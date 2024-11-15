#!/bin/bash

# Exit on error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
for cmd in git gum gh mods; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# Get the default branch from the remote repository
get_default_branch() {
    git remote show origin | grep 'HEAD branch' | cut -d' ' -f5
}

# Generate commit message using conventional commits format
# generate_commit_message() {
#     local type scope message

#     # Get the diff and generate commit message using mods
#     message=$(git diff --cached | mods "Generate a concise git commit message in imperative tense. First word should start with a lowercase letter. Do not include any type prefix.")
    
#     # Using the Conventional Commit format
#     type=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
#     scope=$(gum input --placeholder "scope")

#     # Since the scope is optional, wrap it in parentheses if it has a value.
#     [ -n "$scope" ] && scope="($scope)"

#     echo "$type$scope: $message"
# }

# generate_commit_message() {
#     local type scope message

#     # Get the diff and generate commit message using mods
#     message=$(git diff --cached | mods "You are an expert software engineer.Review the provided context and diffs which are about to be committed to a git repo.Review the diffs carefully.Generate a commit message for those changes.The commit message MUST use the imperative tense.The commit message should be structured as follows: <type>: <title>The commit message can come with an optional description after the title with a blank line.Remember don't make the title too long.Use these for <type>: fix, feat, build, chore, ci, docs, style, refactor, perf, testReply with JUST the commit message, without quotes, comments, questions, etc!")
    
#     # Extract title from potentially multi-line message
#     title=$(echo "$message" | head -n1)
#     description=$(echo "$message" | tail -n+3)

#     # Using the Conventional Commit format
#     type=$(gum choose "fix" "feat" "build" "chore" "ci" "docs" "style" "refactor" "perf" "test")
#     scope=$(gum input --placeholder "scope")

#     # Since the scope is optional, wrap it in parentheses if it has a value.
#     [ -n "$scope" ] && scope="($scope)"

#     if [ -n "$description" ]; then
#         echo "$type$scope: $title"
#         echo
#         echo "$description"
#     else
#         echo "$type$scope: $title"
#     fi
# }

generate_commit_message() {
    local message

    # Get the diff and generate commit message using mods
    message=$(git diff --cached | mods "You are an expert software engineer.Review the provided context and diffs which are about to be committed to a git repo.Review the diffs carefully.Generate a commit message for those changes.The commit message MUST use the imperative tense.The commit message should be structured as follows: <type>: <title>The commit message can come with an optional description after the title with a blank line.Remember don't make the title too long.Use these for <type>: fix, feat, build, chore, ci, docs, style, refactor, perf, testReply with JUST the commit message, without quotes, comments, questions, etc!")

    # Just output the message directly
    echo "$message"
}

# Generate PR title and body
generate_pr_info() {
    local default_branch
    default_branch=$(get_default_branch)

    local type scope pr_title_prefix pr_summary pr_body

    # Using the Conventional Commit format
    type=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
    scope=$(gum input --placeholder "scope")

    # Since the scope is optional, wrap it in parentheses if it has a value.
    [ -n "$scope" ] && scope="($scope)"

    pr_title_prefix="$type$scope"

    gum style --foreground 212 "Generating Pull Request title..."
    pr_summary=$(git diff "$default_branch".. | mods "create a concise Pull Request title that describes the main change. First word should start with a lowercase letter")
    pr_title="$pr_title_prefix: $pr_summary"

    gum style --foreground 212 "Generating Pull Request body..."
    
    # Create sections for the PR template
    local problems changes solutions

    problems=$(git diff "$default_branch".. | mods -f "Describe the problems or issues that needed to be addressed. Focus on why these changes were necessary." --max-tokens 200)
    solutions=$(git diff "$default_branch".. | mods -f "Explain the solutions implemented to address the problems. Include important technical details and implementation choices." --max-tokens 200)
    changes=$(git diff "$default_branch".. | mods -f "Create a bullet-point list of the main changes made in this PR. Each point should be concise and start with a verb in present tense." --max-tokens 200)

    # Construct the PR body using the template
    pr_body="### Problems

$problems

### Solutions

$solutions

### Changes

$changes"

    gh pr create \
        --title "$pr_title" \
        --body "$pr_body"
}

# Main script execution starts here
if [ "$1" = "commit" ]; then
    commit_msg=$(generate_commit_message)
    git commit -m "$commit_msg"
else
    generate_pr_info
fi