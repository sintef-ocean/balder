DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#    -u $(id -u ${USER}):$(id -g ${USER}) \

function run-balder-dev {

  docker run \
         --rm \
         -d \
         -h fkin-weston \
         -e XDG_VTNR=${MY_VTNR:-6} \
         --device /dev/dri \
         --device /dev/input \
         --device /dev/tty0 \
         --device /dev/tty${MY_VTNR:-6} \
         -v /run/udev/data:/run/udev/data:ro \
         -v /tmp/weston-run:/tmp/weston-run \
         --cap-add SYS_TTY_CONFIG \
         fkin/weston /bin/bash -c "/usr/local/bin/startweston --tty=${MY_VTNR:-6} --socket=fkin-weston"

  sleep 0.5

  docker run \
         --rm \
         -it \
         -h fkin-balder-dev \
         -e WAYLAND_DISPLAY=fkin-weston \
         -e XDG_SESSION_TYPE=wayland \
         -e XDG_RUNTIME_DIR=/tmp/weston-run \
         --device /dev/dri \
         --device /dev/input \
         --device /dev/tty0 \
         --device /dev/tty${MY_VTNR:-6} \
         -v /run/udev/data:/run/udev/data:ro \
         -v /tmp/weston-run:/tmp/weston-run \
         -v ${DIR}:/code \
         --cap-add SYS_TTY_CONFIG \
         fkin/balder/build /bin/bash -c "source /opt/opensplice/release.com; bash"

}

function run-balder-runtime {

  docker run \
         --rm \
         -d \
         -h fkin-weston \
         -e XDG_VTNR=${MY_VTNR:-6} \
         --device /dev/dri \
         --device /dev/input \
         --device /dev/tty0 \
         --device /dev/tty${MY_VTNR:-6} \
         -v /run/udev/data:/run/udev/data:ro \
         -v /tmp/weston-run:/tmp/weston-run \
         --cap-add SYS_TTY_CONFIG \
         fkin/weston /bin/bash -c "/usr/local/bin/startweston --tty=${MY_VTNR:-6} --socket=fkin-weston"

  sleep 0.5

  docker run \
         --rm \
         -it \
         -h fkin-balder-runtime \
         -e WAYLAND_DISPLAY=fkin-weston \
         -e XDG_SESSION_TYPE=wayland \
         -e XDG_RUNTIME_DIR=/tmp/weston-run \
         --device /dev/dri \
         --device /dev/input \
         --device /dev/tty0 \
         --device /dev/tty${MY_VTNR:-6} \
         -v /run/udev/data:/run/udev/data:ro \
         -v /tmp/weston-run:/tmp/weston-run \
         --cap-add SYS_TTY_CONFIG \
         fkin/balder/runtime /bin/bash -c "source /opt/opensplice/release.com; bash"

}
