#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Version management helpers.  These functions help to set, save and load the
# following variables:
#
#    PROJECT_GIT_COMMIT - The git commit id corresponding to this
#          source code.
#    PROJECT_GIT_TREE_STATE - "clean" indicates no changes since the git commit id
#        "dirty" indicates source code changes after the git commit id
#        "archive" indicates the tree was produced by 'git archive'
#    PROJECT_GIT_VERSION - "vX.Y" used to indicate the last release version.

# Grovels through git to set a set of env variables.
#
# If PROJECT_GIT_VERSION_FILE, this function will load from that file instead of
# querying git.
version::get_version_vars() {
  if [[ -n ${PROJECT_GIT_VERSION_FILE-} ]]; then
    version::load_version_vars "${PROJECT_GIT_VERSION_FILE}"
    return
  fi

  # If the source was exported through git archive, then
  # we likely don't have a git tree, but these magic values may be filled in.
  # shellcheck disable=SC2016,SC2050
  # Disabled as we're not expanding these at runtime, but rather expecting
  # that another tool may have expanded these and rewritten the source (!)
  if [[ '$Format:%%$' == "%" ]]; then
    PROJECT_GIT_COMMIT='$Format:%H$'
    PROJECT_GIT_TREE_STATE="archive"
    # When a 'git archive' is exported, the '$Format:%D$' below will look
    # something like 'HEAD -> release-1.8, tag: v1.8.3' where then 'tag: '
    # can be extracted from it.
    if [[ '$Format:%D$' =~ tag:\ (v[^ ,]+) ]]; then
     PROJECT_GIT_VERSION="${BASH_REMATCH[1]}"
    fi
  fi

  local git=(git --work-tree "${PROJECT_ROOT}")

  if [[ -n ${PROJECT_GIT_COMMIT-} ]] || PROJECT_GIT_COMMIT=$("${git[@]}" rev-parse "HEAD^{commit}" 2>/dev/null); then
    if [[ -z ${PROJECT_GIT_TREE_STATE-} ]]; then
      # Check if the tree is dirty.  default to dirty
      if git_status=$("${git[@]}" status --porcelain 2>/dev/null) && [[ -z ${git_status} ]]; then
        PROJECT_GIT_TREE_STATE="clean"
      else
        PROJECT_GIT_TREE_STATE="dirty"
      fi
    fi

    # Use git describe to find the version based on tags.
    if [[ -n ${PROJECT_GIT_VERSION-} ]] || PROJECT_GIT_VERSION=$("${git[@]}" describe --tags --abbrev=14 "${PROJECT_GIT_COMMIT}^{commit}" 2>/dev/null); then
      # This translates the "git describe" to an actual semver.org
      # compatible semantic version that looks something like this:
      #   v1.1.0-alpha.0.6+84c76d1142ea4d
      #
      # TODO: We continue calling this "git version" because so many
      # downstream consumers are expecting it there.
      #
      # These regexes are painful enough in sed...
      # We don't want to do them in pure shell, so disable SC2001
      # shellcheck disable=SC2001
      DASHES_IN_VERSION=$(echo "${PROJECT_GIT_VERSION}" | sed "s/[^-]//g")
      if [[ "${DASHES_IN_VERSION}" == "---" ]] ; then
        # shellcheck disable=SC2001
        # We have distance to subversion (v1.1.0-subversion-1-gCommitHash)
        PROJECT_GIT_VERSION=$(echo "${PROJECT_GIT_VERSION}" | sed "s/-\([0-9]\{1,\}\)-g\([0-9a-f]\{14\}\)$/.\1\+\2/")
      elif [[ "${DASHES_IN_VERSION}" == "--" ]] ; then
        # shellcheck disable=SC2001
        # We have distance to base tag (v1.1.0-1-gCommitHash)
        PROJECT_GIT_VERSION=$(echo "${PROJECT_GIT_VERSION}" | sed "s/-g\([0-9a-f]\{14\}\)$/+\1/")
      fi
      if [[ "${PROJECT_GIT_TREE_STATE}" == "dirty" ]]; then
        # git describe --dirty only considers changes to existing files, but
        # that is problematic since new untracked .go files affect the build,
        # so use our idea of "dirty" from git status instead.
        PROJECT_GIT_VERSION+="-dirty"
      fi

      # If PROJECT_GIT_VERSION is not a valid Semantic Version, then refuse to build.
      if ! [[ "${PROJECT_GIT_VERSION}" =~ ^v([0-9]+)\.([0-9]+)(\.[0-9]+)?(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
          echo "PROJECT_GIT_VERSION should be a valid Semantic Version. Current value: ${PROJECT_GIT_VERSION}"
          echo "Please see more details here: https://semver.org"
          exit 1
      fi
    fi
  fi
}

# Saves the environment flags to $1
version::save_version_vars() {
  local version_file=${1-}
  [[ -n ${version_file} ]] || {
    echo "!!! Internal error.  No file specified in version::save_version_vars"
    return 1
  }

  cat <<EOF >"${version_file}"
PROJECT_GIT_COMMIT='${PROJECT_GIT_COMMIT-}'
PROJECT_GIT_TREE_STATE='${PROJECT_GIT_TREE_STATE-}'
PROJECT_GIT_VERSION='${PROJECT_GIT_VERSION-}'
EOF
}

# Loads up the version variables from file $1
version::load_version_vars() {
  local version_file=${1-}
  [[ -n ${version_file} ]] || {
    echo "!!! Internal error.  No file specified in version::load_version_vars"
    return 1
  }

  source "${version_file}"
}

# Prints the value that needs to be passed to the -ldflags parameter of go build
version::ldflags() {
  version::get_version_vars

  local -a ldflags
  function add_ldflag() {
    local key=${1}
    local val=${2}
    ldflags+=(
      "-X '${PROJECT_MODULE}/pkg/version.${key}=${val}'"
    )
  }


  case "$(uname -s)" in
    Darwin*)  parser="-r ${SOURCE_DATE_EPOCH}";;
    *)        parser="--date=@${SOURCE_DATE_EPOCH}"
  esac

  add_ldflag "buildDate" "$(date ${SOURCE_DATE_EPOCH:+${parser}} -u +'%Y-%m-%dT%H:%M:%SZ')"
  if [[ -n ${PROJECT_GIT_COMMIT-} ]]; then
    add_ldflag "gitCommit" "${PROJECT_GIT_COMMIT}"
    add_ldflag "gitTreeState" "${PROJECT_GIT_TREE_STATE}"
  fi

  if [[ -n ${PROJECT_GIT_VERSION-} ]]; then
    add_ldflag "version" "${PROJECT_GIT_VERSION}"
  fi

  # The -ldflags parameter takes a single string, so join the output.
  echo "${ldflags[*]-}"
}
