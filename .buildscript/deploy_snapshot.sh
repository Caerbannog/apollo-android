#!/bin/bash
#
# Deploy a jar, source jar, and javadoc jar to Sonatype's snapshot repo.
#
# Adapted from https://coderwall.com/p/9b_lfq and
# http://benlimmer.com/2013/12/26/automatically-publish-javadoc-to-gh-pages-with-travis-ci/

SLUG="apollographql/apollo-android"
JDK="oraclejdk8"
BRANCH="master"

set -e

if [ "$TRAVIS_REPO_SLUG" != "$SLUG" ]; then
  echo "Skipping snapshot deployment: wrong repository. Expected '$SLUG' but was '$TRAVIS_REPO_SLUG'."
elif [ "$TRAVIS_JDK_VERSION" != "$JDK" ]; then
  echo "Skipping snapshot deployment: wrong JDK. Expected '$JDK' but was '$TRAVIS_JDK_VERSION'."
elif [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo "Skipping snapshot deployment: was pull request."
elif [ "$TRAVIS_BRANCH" != "$BRANCH" ]; then
  echo "Skipping snapshot deployment: wrong branch. Expected '$BRANCH' but was '$TRAVIS_BRANCH'."
else
  echo "Deploying snapshot..."
  ./gradlew uploadArchives -PSONATYPE_NEXUS_USERNAME="${SONATYPE_NEXUS_USERNAME}" -PSONATYPE_NEXUS_PASSWORD="${SONATYPE_NEXUS_PASSWORD}" -x apollo-integration:uploadArchives -x apollo-sample:uploadArchives
  echo "Snapshot deployed!"
  
  echo "Publishing javadoc..."

  cp -R apollo-api/build/docs/javadoc $HOME/javadoc-latest/
  cp -R apollo-gradle-plugin/build/docs/javadoc $HOME/javadoc-latest/
  cp -R apollo-http-cache/build/docs/javadoc $HOME/javadoc-latest/
  cp -R apollo-runtime/build/docs/javadoc $HOME/javadoc-latest/

  cd $HOME
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "travis-ci"
  git clone --quiet --branch=gh-pages https://${GH_TOKEN}@github.com/apollographql/apollo-android gh-pages > /dev/null

  cd gh-pages
  git rm -rf ./javadoc
  cp -Rf $HOME/javadoc-latest ./javadoc
  git add -f .
  git commit -m "Latest javadoc on successful travis build $TRAVIS_BUILD_NUMBER auto-pushed to gh-pages"
  git push -fq origin gh-pages > /dev/null

  echo "Published Javadoc to gh-pages!"
fi
