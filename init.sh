env | grep ^TRAVIS # for troubleshooting

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the grails version for the current project, downloading it if necessary
function _grails {
    local grails_bin=/usr/bin/grails
    local grails_home
    if [[ -f application.properties ]]; then
        local grails_version=$(grep 'app\.grails\.version' application.properties \
                | cut -d = -f 2)
        local dir=$(echo ~/grails/grails-"$grails_version")
        if [[ ! -d $dir ]]; then
            mkdir -p ~/grails
            local tmpfile="/tmp/grails-${grails_version}.zip"
            curl -o "$tmpfile" \
                    "http://dist.springframework.org.s3.amazonaws.com/release/GRAILS/grails-${grails_version}.zip"
            unzip -q "$tmpfile" -d ~/grails
        fi
        grails_bin="$dir/bin/grails"
        grails_home="$dir"
    fi

    GRAILS_HOME=$grails_home $grails_bin "$@"
}

function grails {
    (set -e; _grails "$@")
}

# print the name of the relevant branch
function get_branch {
    local branch_name=$(git symbolic-ref -q HEAD)
    local readonly pr_label=$(get_pr_label)
    branch_name=${branch_name##refs/heads/}
    branch_name=${branch_name:-HEAD}

    if [[ -n $pr_label ]]; then
        echo "$pr_label" | cut -d: -f2
        return
    fi

    #travis works with a detached HEAD, and we have too look at its env vars
    if [[ $TRAVIS = true && $branch_name = 'HEAD' ]]; then
        if [[ $TRAVIS_PULL_REQUEST != false ]]; then
            # find the remote branch that points to the second parent commit
            local t=$(git ls-remote --heads origin | grep $(git rev-parse HEAD^2))
            if [[ -n $t ]]; then
                branch_name=${t##*refs/heads/}
            elif [[ -n $TRAVIS_BRANCH ]]; then
                # in pull requests, $TRAVIS_BRANCH is the branch we're merging
                # into, not from. Nevertheless, fall back on it if we don't find
                # the branch name we're merging from. This happens if we're the
                # pull requests comes from a foreign repository
                branch_name="$TRAVIS_BRANCH"
            fi
        elif [[ -n "$TRAVIS_BRANCH" ]]; then
            branch_name="$TRAVIS_BRANCH"
        fi
    fi
    echo $branch_name
}

# see whether a given project has the passed branch
# ignores master because bamboo already publishes artifacts in that case
function has_dedicated_branch {
    local readonly remote_repos="$1"
    local readonly branch="$2"
    local readonly do_master=$3 #yes/no

    if [[ $branch = HEAD ]]; then
        echo "Could not identify a branch for this environment"
        return 1
    fi

    if [[ $do_master = 'no' && $branch = master ]]; then
        echo "Current branch is $branch, skipping check for branch in " \
             $remote_repos
        return 1
    fi

    if ! git ls-remote \
            --exit-code "$remote_repos" "$branch" \
            > /dev/null; then
        echo "No branch $branch at $remote_repos"
       return 1
    fi

    echo "Found branch $branch at $remote_repos"
    return 0
}

# checkout the related branch for a related project
# returns 2 in case of error, 0 if there the branch exists and was
# checked out and 1 if the branch does not exist
function maybe_checkout_project_branch {
    local readonly remote_repos="git://github.com/${1}.git"
    local readonly target_dir="${2:-${1##*/}}"
    local readonly branch="$(get_branch)"
    local readonly repo_owner=$(cut -d/ -f1 <<< "$1")
    local readonly do_master=$([[ $repo_owner != 'thehyve' ]] \
            && echo yes || echo no)

    if has_dedicated_branch "$remote_repos" "$branch" "$do_master"; then
        git clone --depth=50 --branch="$branch" "$remote_repos" "$target_dir"
        if [[ $? -ne 0 ]]; then
            return 2
        fi
        return 0
    fi

    return 1
}

PR_DATA_LOCATION=/tmp/pr_data
function get_pr_label {
    local cred_pars=()

    if [[ -z $TRAVIS_PULL_REQUEST ]]; then
        return
    fi

    if [[ -n $GITHUB_CREDS ]]; then
        cred_pars=('-u' "$GITHUB_CREDS")
    fi

    if [[ ! -f $PR_DATA_LOCATION ]]; then
        curl -f -s -o "$PR_DATA_LOCATION" \
            https://api.github.com/repos/"$TRAVIS_REPO_SLUG"/pulls/$TRAVIS_PULL_REQUEST \
            "${cred_pars[@]}"
        if [[ $? -ne 0 ]]; then
            echo "Could not fetch PR data" >&2
            exit 1
        fi
    fi

    if [[ -f /usr/share/perl5/JSON.pm ]]; then
        perl "$DIR"/extract_label.pl < "$PR_DATA_LOCATION"
    elif [[ $(php -r 'echo function_exists("json_decode");') -eq 1 ]]; then
        php "$DIR"/extract_label.php < "$PR_DATA_LOCATION"
    else
        sudo apt-get install -y -qq libjson-perl > /dev/null
        perl "$DIR"/extract_label.pl < "$PR_DATA_LOCATION"
    fi

}

function travis_get_owner {
    local readonly pr_label=$(get_pr_label)
    if [[ -n $pr_label ]]; then
        echo "$pr_label" | cut -d: -f1
    else
        echo "$TRAVIS_REPO_SLUG" | cut -d/ -f1
    fi
}

# vim: et tw=80 ts=4 sw=4:
