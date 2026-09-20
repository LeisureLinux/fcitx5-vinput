# CPack pre-build hook for the DEB generator.
#
# CPack's DEB generator leaves several packaging conventions to the caller:
#   * /usr/share/doc/<pkg>/copyright and changelog.Debian.gz are not installed;
#   * man pages are shipped uncompressed, while Debian policy expects them
#     gzipped;
#   * CPACK_STRIP_FILES only strips install(TARGETS) binaries, not the
#     bundled sherpa-onnx libraries shipped via install(FILES);
#   * staging keeps the builder's umask, so directories end up group writable.
# This script fills those gaps on the staging tree just before the .deb is
# assembled.  It is a no-op for every other generator, since RPM handles
# these concerns by itself.
#
# Requires CMake >= 3.19 (CPACK_PRE_BUILD_SCRIPTS).

if(NOT CPACK_GENERATOR STREQUAL "DEB")
    return()
endif()

set(_stage "${CPACK_TEMPORARY_DIRECTORY}")
if(NOT _stage)
    message(FATAL_ERROR "vinput: CPACK_TEMPORARY_DIRECTORY is not set; cannot stage DEB metadata")
endif()

set(_pkg "${CPACK_DEBIAN_PACKAGE_NAME}")
set(_doc "${_stage}/usr/share/doc/${_pkg}")
file(MAKE_DIRECTORY "${_doc}")

find_program(_GZIP gzip)
if(NOT _GZIP)
    message(FATAL_ERROR "vinput: gzip is required to build the DEB documentation")
endif()

# ---------------------------------------------------------------------------
# 1. Machine-readable copyright (DEP-5).
# ---------------------------------------------------------------------------
set(_copyright_src "${CMAKE_CURRENT_LIST_DIR}/copyright")
if(NOT EXISTS "${_copyright_src}")
    message(FATAL_ERROR "vinput: missing copyright source ${_copyright_src}")
endif()
configure_file("${_copyright_src}" "${_doc}/copyright" COPYONLY)

# ---------------------------------------------------------------------------
# 2. Debian changelog.  A non-native package must ship changelog.Debian.gz in
#    Debian changelog format.  Entries are taken from the CHANGELOG.md section
#    matching this version when one exists, otherwise a release line is used.
# ---------------------------------------------------------------------------
set(_deb_version "${CPACK_DEBIAN_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE}")
string(TIMESTAMP _build_date "%a, %d %b %Y %H:%M:%S +0000" UTC)

set(_entries "")
set(_changelog_src "${CMAKE_CURRENT_LIST_DIR}/../../CHANGELOG.md")
if(EXISTS "${_changelog_src}")
    file(READ "${_changelog_src}" _md)
    string(REPLACE "\r\n" "\n" _md "${_md}")
    string(REPLACE "\n" ";" _md_lines "${_md}")
    set(_in_section FALSE)
    foreach(_line IN LISTS _md_lines)
        if(_line MATCHES "^## +\\[${CPACK_DEBIAN_PACKAGE_VERSION}\\]")
            set(_in_section TRUE)
            continue()
        endif()
        if(_in_section AND _line MATCHES "^## ")
            break()
        endif()
        if(_in_section AND _line MATCHES "^- ")
            string(REGEX REPLACE "^- +" "" _entry "${_line}")
            # Drop the light markdown emphasis and links CHANGELOG.md uses so
            # the result reads as plain changelog text.
            string(REGEX REPLACE "\\[([^]]*)\\]\\([^)]*\\)" "\\1" _entry "${_entry}")
            string(REGEX REPLACE "\\*\\*" "" _entry "${_entry}")
            string(REGEX REPLACE "`" "" _entry "${_entry}")
            string(STRIP "${_entry}" _entry)
            string(APPEND _entries "  * ${_entry}\n")
        endif()
    endforeach()
endif()
if(NOT _entries)
    set(_entries "  * New upstream release ${CPACK_DEBIAN_PACKAGE_VERSION}.\n")
endif()

set(_changelog_text
"${_pkg} (${_deb_version}) unstable; urgency=medium

${_entries}
 -- ${CPACK_DEBIAN_PACKAGE_MAINTAINER}  ${_build_date}
")
file(WRITE "${_doc}/changelog.Debian" "${_changelog_text}")
execute_process(COMMAND "${_GZIP}" -9 -n -f "${_doc}/changelog.Debian"
    RESULT_VARIABLE _gz_result)
if(NOT _gz_result EQUAL 0)
    message(FATAL_ERROR "vinput: gzip failed for changelog.Debian (${_gz_result})")
endif()

# 2b. Upstream changelog.  gzip refuses to compress a file already named *.gz,
#     so stage it under its plain name and compress that instead.
if(EXISTS "${_changelog_src}")
    configure_file("${_changelog_src}" "${_doc}/changelog" COPYONLY)
    execute_process(COMMAND "${_GZIP}" -9 -n -f "${_doc}/changelog"
        RESULT_VARIABLE _gz_result)
    if(NOT _gz_result EQUAL 0)
        message(FATAL_ERROR "vinput: gzip failed for upstream changelog (${_gz_result})")
    endif()
endif()

# ---------------------------------------------------------------------------
# 3. Compress man pages, as dpkg's packaging practice (and dh_installman) does.
# ---------------------------------------------------------------------------
file(GLOB_RECURSE _man_pages LIST_DIRECTORIES false "${_stage}/usr/share/man/*")
foreach(_man IN LISTS _man_pages)
    if(IS_DIRECTORY "${_man}" OR _man MATCHES "(\\.gz|\\.bz2|\\.xz)$")
        continue()
    endif()
    # Section is a single digit with an optional subsection suffix, e.g.
    # vinput.1, foo.3pm and zh_CN/vinput.1.
    if(_man MATCHES "/man[1-9][a-z_]*/[^/]+\\.[1-9][a-z_]*$")
        execute_process(COMMAND "${_GZIP}" -9 -n "${_man}" RESULT_VARIABLE _man_result)
        if(NOT _man_result EQUAL 0)
            message(FATAL_ERROR "vinput: gzip failed for man page ${_man} (${_man_result})")
        endif()
    endif()
endforeach()

# ---------------------------------------------------------------------------
# 4. Strip ELF payloads.  CPACK_STRIP_FILES does not cover the bundled
#    libraries installed through install(FILES), so handle the whole tree.
# ---------------------------------------------------------------------------
find_program(_OBJCOPY NAMES objcopy)
if(NOT _OBJCOPY)
    message(FATAL_ERROR "vinput: objcopy is required to strip the DEB payload")
endif()
file(GLOB_RECURSE _staged_files LIST_DIRECTORIES false "${_stage}/*")
foreach(_file IN LISTS _staged_files)
    if(IS_DIRECTORY "${_file}")
        continue()
    endif()
    # ELF magic: 0x7f 'E' 'L' 'F'.  Only the first four bytes are read.
    file(READ "${_file}" _magic LIMIT 4 HEX)
    if(_magic STREQUAL "7f454c46")
        execute_process(COMMAND "${_OBJCOPY}" --strip-unneeded "${_file}"
            RESULT_VARIABLE _strip_result)
        if(NOT _strip_result EQUAL 0)
            message(FATAL_ERROR "vinput: objcopy failed for ${_file} (${_strip_result})")
        endif()
    endif()
endforeach()

# ---------------------------------------------------------------------------
# 5. Normalise permissions.  CPack's staging inherits the builder's umask,
#    which yields group/other-writable directories; Debian expects 0755/0644.
# ---------------------------------------------------------------------------
# 5. Normalise permissions.  CPack's staging inherits the builder's umask, which
#    yields group-writable directories and files; Debian expects 0755/0644.
#    Directories are globbed separately because GLOB_RECURSE omits them unless
#    LIST_DIRECTORIES is enabled.
# ---------------------------------------------------------------------------
file(GLOB_RECURSE _staged_dirs LIST_DIRECTORIES true "${_stage}/*")
foreach(_path IN LISTS _staged_dirs)
    if(IS_DIRECTORY "${_path}")
        file(CHMOD "${_path}"
            PERMISSIONS
            OWNER_READ OWNER_WRITE OWNER_EXECUTE
            GROUP_READ GROUP_EXECUTE
            WORLD_READ WORLD_EXECUTE)
    endif()
endforeach()

find_program(_TEST_EXECUTABLE NAMES test)
foreach(_file IN LISTS _staged_files)
    set(_file_mode OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
    if(_TEST_EXECUTABLE)
        execute_process(COMMAND "${_TEST_EXECUTABLE}" -x "${_file}"
            RESULT_VARIABLE _is_executable)
        if(_is_executable EQUAL 0)
            set(_file_mode
                OWNER_READ OWNER_WRITE OWNER_EXECUTE
                GROUP_READ GROUP_EXECUTE
                WORLD_READ WORLD_EXECUTE)
        endif()
    endif()
    file(CHMOD "${_file}" PERMISSIONS ${_file_mode})
endforeach()
