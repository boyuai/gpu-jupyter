#!/usr/bin/env bash
cd $(cd -P -- "$(dirname -- "$0")" && pwd -P)

# Set the path of the generated Dockerfile
export DOCKERFILE=".build/Dockerfile"
export STACKS_DIR=".build/docker-stacks"
export HEAD_COMMIT="c1c32938438151c7e2a22b5aa338caba2ec01da2"

while [[ "$#" -gt 0 ]]; do case $1 in
  -c|--commit) HEAD_COMMIT="$2"; shift;;
  *) echo "Unknown parameter passed: $1" &&
    echo "Usage: $0 -c [sha-commit] # set the head commit of the docker-stacks submodule
    (https://github.com/jupyter/docker-stacks/commits/master). default: $HEAD_COMMIT."; exit 1;;
esac; shift; done


# Clone if docker-stacks doesn't exist, and set to the given commit or the default commit
ls $STACKS_DIR/README.md  > /dev/null 2>&1  || (echo "Docker-stacks was not found, cloning repository" \
 && git clone https://github.com/jupyter/docker-stacks.git $STACKS_DIR)
echo "Set docker-stacks to commit '$HEAD_COMMIT'."
if [[ "$HEAD_COMMIT" == "latest" ]]; then
  echo "WARNING, the latest commit of docker-stacks is used. This may result in version conflicts"
  cd $STACKS_DIR && git pull && cd -
else
  export GOT_HEAD="false"
  cd $STACKS_DIR && git reset --hard "$HEAD_COMMIT" > /dev/null 2>&1  && cd - && export GOT_HEAD="true"
  echo "$HEAD"
  if [[ "$GOT_HEAD" == "false" ]]; then
    echo "Given sha-commit is invalid."
    echo "Usage: $0 -c [sha-commit] # set the head commit of the docker-stacks submodule (https://github.com/jupyter/docker-stacks/commits/master)."
    exit 2
  else
    echo "Set head to given commit."
  fi
fi

# Write the contents into the DOCKERFILE and start with the header
cat src/Dockerfile.header > $DOCKERFILE

echo "
############################################################################
#################### Dependency: jupyter/base-image ########################
############################################################################
" >> $DOCKERFILE
cat $STACKS_DIR/base-notebook/Dockerfile | grep -v BASE_CONTAINER >> $DOCKERFILE

# copy files that are used during the build:
cp $STACKS_DIR/base-notebook/jupyter_notebook_config.py .build/
cp $STACKS_DIR/base-notebook/fix-permissions .build/
cp $STACKS_DIR/base-notebook/start.sh .build/
cp $STACKS_DIR/base-notebook/start-notebook.sh .build/
cp $STACKS_DIR/base-notebook/start-singleuser.sh .build/
chmod 755 .build/*

echo "
############################################################################
################# Dependency: jupyter/minimal-notebook #####################
############################################################################
" >> $DOCKERFILE
cat $STACKS_DIR/minimal-notebook/Dockerfile | grep -v BASE_CONTAINER >> $DOCKERFILE
