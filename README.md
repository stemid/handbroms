# Handbroms

Bash script that runs HandBrakeCLI in parallel to process multiple files from MKV to MP4 for HTML5 video.

Requires Bash >= 4.3 for the ``wait -n`` feature.

**Observe:** Only supports MKV for now. Will add more filetypes as I go through my media library. I made this to convert files for use with [Streama](https://github.com/dularion/streama).

## Usage

	$ handbroms.sh dir/
	$ handbroms.sh file.mkv

## Subtitles

Will merge video and subtitles as long as name is the same, for example; video1.mkv and video1.srt will be combined with HandBrakeCLI ``--srt-file`` argument.

# Install HandBrakeCLI on Fedora/CentOS

## Dependencies

Install build-deps for HandBrakeCLI and mediainfo.

  $ sudo dnf install opus-devel libxml2-devel jansson-devel libvorbis-devel \
		libass-devel libsamplerate-devel libtheora-devel bzip2-devel gmake

### Fedora libmp3lame

On Fedora you can install lame-devel but on CentOS you might have to build it or install it from other 3rd party repos.

	$ sudo dnf install lame-devel

The build-process on CentOS is straightforward, but I recommend setting ``--prefix=/usr/local`` so after install you edit ``/etc/ld.so.conf.d/usr_local.conf`` and add the path /usr/local/lib into it.

Then run ldconfig.

	$ echo '/usr/local/lib' | sudo tee /etc/ld.so.conf.d/usr_local.conf
	$ sudo ldconfig

This happily separates your custom built libraries from package installs.

### libx264

	$ sudo dnf install yasm
	$ git clone --depth 1 git://git.videolan.org/x264
	$ cd x264
	$ ./configure --prefix=/usr/local --enable-shared
	$ make
	$ sudo make install
	$ sudo ldconfig

## Build

Now unpack and compile HandBrakeCLI, here's an example with version 1.0.1.

	$ mkdir $HOME/bin
	$ tar -xvjf HandBrake-1.0.1.tar.bz2
	$ cd HandBrake-1.0.1
	$ ./configure --disable-gtk --disable-gst
	$ cd build
	$ gmake
	$ cp HandBrakeCLI $HOME/bin

I disable GTK and gstreamer support.

Now ensure HandBrakeCLI is in your PATH, I use ``$HOME/bin`` but that's not always included in PATH.

# Install exiftool

This queries files for media info.

	$ sudo dnf install perl-Image-ExifTool
