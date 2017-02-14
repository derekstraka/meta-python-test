def targets = [ 'qemux86-64' ]

def machine_builds = [:]

for (int i = 0; i < targets.size(); i++) {
    def machine = targets.get(i)

    machine_build["$machine"] = {
        node {
            try {
                stage("checkout $machine") {
                    checkout scm
                }
                stage("setup-env $machine") {
                    sh "./scripts/setup-env.sh"
                }
                stage("fetch $machine") {
                    sh "GIT_LOCAL_REF_DIR=/srv/git-cache/ ./scripts/fetch.sh master"
                }
                stage("build $machine") {
                    sh "MACHINE=${machine} ./scripts/build.sh"
                }
            } catch (e) {
                echo "Caught: ${e}"
                throw e
            } finally {
                stage("cleanup $machine") {
                    sh "./scripts/cleanup-env.sh"
                    deleteDir()
                }
            }
        }
    }
}

parallel machine_build
