module.exports = {
    branches: "main",
    repositoryUrl: "https://github.com/Henrydoglass/bootcamp32.git",
    plugins: [
      '@semantic-release/commit-analyzer',
      '@semantic-release/release-notes-generator',
      '@semantic-release/git',
      '@semantic-release/github']
 }