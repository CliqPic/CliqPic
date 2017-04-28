#!/bin/bash

help() {
    echo -e "This command automates the deploy process for this application"
    echo -e "Usage: deploy.sh [current_version] [new_version]"
}

if [ -z $1 ]
then
    echo -e "No arguments supplied\n"
    help
    exit 1
fi

if [ -z $2 ]
then
    echo -e "New version not specified\n"
    help
    exit 1
fi

# Update the version numbers located in the Dockerfile, compose config, and Beanstalk config
sed -i '' s/$1/$2/ {Dockerfile,docker-compose.yml,Dockerrun.aws.json} 2>/dev/null

# Commit those changes
git commit -am "Bump version to $2"

# and tag them
git tag -a v$2 -m "cliq-pic version $2"

# push everything
git push origin HEAD
git push --tags

# log into the container registry
$(aws ecr get-login)

docker-compose build server

# Tag the new image correctly so we can push it to the registry
docker tag amdirent/cliq-pic:$2 402239435993.dkr.ecr.us-east-1.amazonaws.com/clients/cliq-pic:$2

# Push it to the registry
docker push 402239435993.dkr.ecr.us-east-1.amazonaws.com/clients/cliq-pic:$2



# Finally, deploy to beanstalk
if command -v eb > /dev/null 2>&1
then
    eb deploy Custom-env -l "cliq-pic-$2"
elif [ -f "$HOME/.local/bin/eb" ]
then
    $("$HOME/.local/bin/eb") deploy Custom-env -l "cliq-pic-$2"
else
    echo -e "Elastic Beanstalk CLI not found.  Please deploy the application manually now."
fi
