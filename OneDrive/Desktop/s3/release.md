1. Install the semantic-release on your local environment:
    npm install --save-dev semantic-release
    $ npm install semantic-release @semantic-release/git @semantic-release/github -D
2. Create a config file (release.config.js) in the project with the contents below:
     release.config.js
    ====================

module.exports = {
   branches: "main",
   repositoryUrl: "https://github.com/<yourname>/actionstest.git",
   plugins: [
     '@semantic-release/commit-analyzer',
     '@semantic-release/release-notes-generator',
     '@semantic-release/git',
     '@semantic-release/github']
}

3. Add your project to the repo:
       git add .

4. Commit your project to the repo using conventional commits. Your commit messages should start with:

    fix:                  ......for a patch version
    feat:                 ......for a minor version
    BREAKING CHANGE:      .......for a major version

4. Add step in the CI workflow:

name: release workflow

on: [workflow_dispatch]

jobs:
  run-shell-command:
    permissions:
      contents: write
      issues: write
      pull-requests: write
    runs-on: ubuntu-latest
    steps:
      - name: checkout
        uses: actions/checkout@v3 # clone a repository
      - name: release
        run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}