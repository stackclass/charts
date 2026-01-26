# List all available commands
default:
    just --list

# Fetch latest release version from GitHub
[private]
fetch-github-version repo:
    #!/usr/bin/env bash
    set -euo pipefail
    # Get latest release tag from GitHub API
    version=$(curl -s "https://api.github.com/repos/stackclass/{{ repo }}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [ -z "$version" ]; then
        echo "Error: Failed to fetch version from GitHub" >&2
        exit 1
    fi
    echo "$version"

# Bump chart version (interactive, fetches versions from GitHub)
bump-version:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Fetching latest versions from GitHub..."
    latest_backend_version=$(just fetch-github-version backend)
    latest_frontend_version=$(just fetch-github-version frontend)
    current_chart_version=$(grep -m1 '^version: ' charts/stackclass/Chart.yaml | sed 's/version: //')

    # Get current image tags from values.yaml
    current_backend_tag=$(grep -A1 'repository: ghcr.io/stackclass/stackclass-server' charts/stackclass/values.yaml | grep 'tag:' | sed -E 's/.*tag: v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    current_frontend_tag=$(grep -A1 'repository: ghcr.io/stackclass/frontend' charts/stackclass/values.yaml | grep 'tag:' | sed -E 's/.*tag: v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

    echo ""
    echo "Current versions:"
    echo "  Chart version:    $current_chart_version"
    echo "  Backend tag:      $current_backend_tag"
    echo "  Frontend tag:     $current_frontend_tag"
    echo ""
    echo "Latest GitHub releases:"
    echo "  Backend:          $latest_backend_version"
    echo "  Frontend:         $latest_frontend_version"
    echo ""

    # Prompt for versions
    read -p "Backend version [$latest_backend_version]: " backend_version
    backend_version=${backend_version:-$latest_backend_version}

    read -p "Frontend version [$latest_frontend_version]: " frontend_version
    frontend_version=${frontend_version:-$latest_frontend_version}

    read -p "New chart version [$current_chart_version]: " chart_version
    chart_version=${chart_version:-$current_chart_version}

    echo ""

    # Validate version formats
    if ! [[ "$backend_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Backend version must be in format X.Y.Z"
        exit 1
    fi
    if ! [[ "$frontend_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Frontend version must be in format X.Y.Z"
        exit 1
    fi
    if ! [[ "$chart_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Chart version must be in format X.Y.Z"
        exit 1
    fi

    echo "=== Updating versions ==="
    echo "Chart version:    $chart_version"
    echo "Backend version:  $backend_version"
    echo "Frontend version: $frontend_version"
    echo ""

    # Update Chart.yaml version
    sed -i '' -E \
        's/^version: [0-9]+\.[0-9]+\.[0-9]+/version: '"$chart_version"'/' \
        charts/stackclass/Chart.yaml
    echo "✓ Updated charts/stackclass/Chart.yaml (version)"

    # Update backend image tag
    sed -i '' -E \
        '/repository: ghcr.io\/stackclass\/stackclass-server/,/tag:/ s/tag: v[0-9]+\.[0-9]+\.[0-9]+/tag: v'"$backend_version"'/' \
        charts/stackclass/values.yaml
    echo "✓ Updated charts/stackclass/values.yaml (backend tag)"

    # Update frontend image tag
    sed -i '' -E \
        '/repository: ghcr.io\/stackclass\/frontend/,/tag:/ s/tag: v[0-9]+\.[0-9]+\.[0-9]+/tag: v'"$frontend_version"'/' \
        charts/stackclass/values.yaml
    echo "✓ Updated charts/stackclass/values.yaml (frontend tag)"

    echo ""
    echo "=== Done! Run 'just release' to commit and push. ==="

# Release chart (commit, tag, push)
release:
    #!/usr/bin/env bash
    set -euo pipefail

    confirm() {
        read -p "$1 [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    }

    # Get current versions
    chart_version=$(grep -m1 '^version: ' charts/stackclass/Chart.yaml | sed 's/version: //')
    backend_version=$(grep -A1 'repository: ghcr.io/stackclass/stackclass-server' charts/stackclass/values.yaml | grep 'tag:' | sed -E 's/.*tag: v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    frontend_version=$(grep -A1 'repository: ghcr.io/stackclass/frontend' charts/stackclass/values.yaml | grep 'tag:' | sed -E 's/.*tag: v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

    echo "=== Release chart v$chart_version ==="
    echo "Backend version:  v$backend_version"
    echo "Frontend version: v$frontend_version"
    echo ""

    echo "Changes to be committed:"
    git status --short
    echo ""

    # Step 1: Commit
    if confirm "Run 'git add -A && git commit'?"; then
        git add -A
        git commit -m "chore: bump version to $chart_version (backend=$backend_version, frontend=$frontend_version)"
        echo ""
    else
        echo "Aborted at commit step."
        exit 0
    fi

    # Step 2: Tag
    if confirm "Run 'git tag v$chart_version'?"; then
        git tag -m "v$chart_version" "v$chart_version"
        echo ""
    else
        echo "Aborted at tag step."
        exit 0
    fi

    # Step 3: Push
    if confirm "Run 'git push origin main v$chart_version'?"; then
        git push origin main "v$chart_version"
        echo ""
        echo "=== Chart v$chart_version released! ==="
    else
        echo "Aborted at push step."
        exit 0
    fi
