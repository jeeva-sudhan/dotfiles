#!/usr/bin/env ruby

# file location: <anywhere>

# This script is used to install the dotfiles from this repo/folder structure to the user's home folder
# It can be invoked from any location as long as its in the PATH (and you don't need to specify the fully qualified name while invoking it).
# It can handle nested files.
# If there is already a real file (not a symbolic link), then the script will move that file into this repo, and then create the corresponding symlink. This helps preserve the current settings from the user without forcefully overriding from my repo.
# Special handling (rename + copy instead of symlink) for '.gitattributes' and '.gitignore'
# To run it, just invoke by `install-dotfiles.rb` if this folder is already setup in the PATH

# It assumes the following:
#   1. Ruby language is present in the system prior to this script being run.

require "#{__dir__}/utilities/string.rb"
require 'fileutils'
require 'find'

def override_into_home_folder(file, dotfiles_dir_length, copy_instead_of_symlink)
  target_file_name = File.join(ENV["HOME"], file[dotfiles_dir_length..-1])

  puts "Processing #{file.yellow} --> #{target_file_name.yellow}"

  # create the nested folder for the target
  FileUtils.mkdir_p(File.dirname(target_file_name))

  # move the real file into the repo folder
  FileUtils.mv(target_file_name, file, force: true, verbose: true) if File.exist?(target_file_name) && !File.symlink?(target_file_name)

  if copy_instead_of_symlink
    # copy from repo to target location
    FileUtils.cp(file, target_file_name)
  else
    # symlink from repo to target location
    FileUtils.ln_sf(file, target_file_name)
  end
end

puts "Starting to install dotfiles".green
dotfiles_dir = File.expand_path(File.join(__dir__, '..', 'files'))
dotfiles_dir_length = dotfiles_dir.length + 1
Find.find(dotfiles_dir) do |file|
  next if File.directory?(file) || file.end_with?('.DS_Store') || file.match?(/\.zwc/)

  # git doesn't handle symlinks, so these 2 files have to be handled separately
  # remove 'custom' and the file path from the name of the file
  custom_removal = ['custom.gitignore', 'custom.gitattributes'].include?(File.basename(file)) ? 'custom'.length : 0
  override_into_home_folder(file, dotfiles_dir_length + custom_removal, custom_removal > 0)
end

puts "Since the '.gitignore' and '.gitattributes' files are COPIED over, any new changes being pulled in (from a newer version of the upstream repo) need to be manually reconciled between this repo and your home folder".red
