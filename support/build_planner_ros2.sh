#!/usr/bin/env bash
# Build the optional embedded MPC/controller bundle from an existing workspace.
set -euo pipefail

planner_setup_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "Usage: $0 --workspace PATH [--distro humble|jazzy]"
  echo "Builds existing source checkouts; does not import or launch anything."
}

planner_workspace=""
planner_distro="${ROS_DISTRO:-}"
while (($#)); do
  case "$1" in
    --workspace|--distro)
      if (($# < 2)); then usage >&2; exit 2; fi
      if [[ "$1" == --workspace ]]; then planner_workspace="$2"; else planner_distro="$2"; fi
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if [[ -z "$planner_workspace" || ! -d "$planner_workspace/src" ]]; then
  echo "An existing workspace with a src directory is required." >&2
  exit 2
fi
if [[ "$planner_distro" != humble && "$planner_distro" != jazzy ]]; then
  echo "Select ROS 2 humble or jazzy with --distro or ROS_DISTRO." >&2
  exit 2
fi
if [[ ! -r "/opt/ros/$planner_distro/setup.bash" ]]; then
  echo "ROS 2 $planner_distro is not installed under /opt/ros." >&2
  exit 2
fi

# ROS setup files may read unset variables.
set +u
source "/opt/ros/$planner_distro/setup.bash"
set -u

planner_packages=()
while IFS= read -r planner_package; do
  [[ -z "$planner_package" || "$planner_package" == \#* ]] && continue
  planner_packages+=("$planner_package")
done < "$planner_setup_dir/config/$planner_distro/planner_list.txt"

cd -- "$planner_workspace"
# colcon diagnoses duplicate package checkouts before building. The supplied
# planner.repos is for a clean source tree; do not duplicate existing Nav2 copies.
colcon list --base-paths src >/dev/null
colcon build --base-paths src --packages-up-to "${planner_packages[@]}" \
  --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
