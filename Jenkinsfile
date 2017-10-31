properties(
    [
        [
            $class: 'BuildDiscarderProperty',
            strategy: [$class: 'LogRotator', numToKeepStr: '5']
        ],
        pipelineTriggers([cron('@daily')]),
    ]
)

def targets = [ 'qemux86-64' ]

def machine_builds = [:]

for (int i = 0; i < targets.size(); i++) {
    def machine = targets.get(i)

    machine_builds["$machine"] = {
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
                stage("build glibc $machine") {
                    sh "MACHINE=${machine} ./scripts/build.sh"
                }
                stage("build musl $machine") {
                    sh "MACHINE=${machine} TCLIBC=musl ./scripts/build.sh"
                }
            } catch (e) {
                echo "Caught: ${e}"
                throw e
            } finally {
                stage("Archive build artifacts") {
                    archiveArtifacts allowEmptyArchive: true, artifacts: 'artifacts/**', fingerprint: true
                }
                stage("push build cache $machine") {
                    sh "./scripts/publish-build-cache.sh master"
                }
                stage("cleanup $machine") {
                    sh "./scripts/cleanup-env.sh"
                    deleteDir()
                }
            }
        }
    }
}

parallel machine_builds
