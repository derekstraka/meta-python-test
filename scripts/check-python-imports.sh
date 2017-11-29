#!/bin/bash

# Grab the MACHINE from the environment; otherwise, set it to a sane default
export MACHINE="${MACHINE-qemux86-64}"

LOG_FILE="import-errors-raw.txt"

# What to build
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd build/tmp/deploy/images/$MACHINE/ &> /dev/null

echo "" > ${LOG_FILE}

for image in `ls *.tar.bz2`; do
    if [ -L $image ]; then
        continue
    fi

    error_file="errors.txt"
    tmp_dir=`mktemp -d`

    echo "Extracting ${image} to ${tmp_dir}"
    tar -jxf ${image} -C ${tmp_dir}

    cat << EOF > ${tmp_dir}/bin/py2-check-import 
#!/bin/sh
for file in \`find /usr/lib/python2*/site-packages/ | grep py$\`; do 
    (>&2 echo \$file); 
    python \$file >> ${error_file} 2>&1; 
done
EOF

    cat << EOF > ${tmp_dir}/bin/py3-check-import 
#!/bin/sh
for file in \`find /usr/lib/python3*/site-packages/ | grep py$\`; do 
    (>&2 echo \$file); 
    python3 \$file >> ${error_file} 2>&1; 
done
EOF

    chmod 755 ${tmp_dir}/bin/py3-check-import  ${tmp_dir}/bin/py2-check-import

    echo "Checking python2 imports"
    sudo chroot ${tmp_dir} py2-check-import 2> /dev/null

    echo "Checking python3 imports"
    sudo chroot ${tmp_dir} py3-check-import 2> /dev/null

    echo "#########################################################################################" >> ${LOG_FILE}
    echo "${image}" >> ${LOG_FILE}

    ${SCRIPT_DIR}/filter_exceptions.py -f ${tmp_dir}/${error_file} -e SystemError >> ${LOG_FILE}

    rm -rf ${tmp_dir}
done

popd &> /dev/null

mv build/tmp/deploy/images/$MACHINE/${LOG_FILE} artifacts

exit 0



