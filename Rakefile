require 'visual_studio'
require 'fileutils'

CONFIGURATIONS = %i{debug development release}
PLATFORMS = %i{windows macosx linux}
ARCHITECTURES = %i{x86 x86_64}
TOOLCHAINS = %i{msvc gcc clang+llvm}

# TOOLCHAIN=msvc PLATFORM=windows ARCHS=x86,x86_64 CONFIGURATIONS=debug,development,release rake build

task :build do
  puts "Building LuaJIT..."

  FileUtils.mkdir_p ['_build/lib', '_build/bin']

  configurations = ENV['CONFIGURATIONS'] ? ENV['CONFIGURATIONS'].split(',').map(&:to_sym) : CONFIGURATIONS
  configurations.each{|config| raise "Unknown configuration '#{config}'!" unless CONFIGURATIONS.include?(config)}
  platform = ENV['PLATFORM'].to_sym
  raise "Unknown platform '#{platform}'!" unless PLATFORMS.include?(platform)
  architectures = ENV['ARCHS'] ? ENV['ARCHS'].split(',').map(&:to_sym) : ARCHITECTURES
  architectures.each{|architecture| raise "Unknown architecture '#{architecture}'!" unless ARCHITECTURES.include?(architecture)}

  case ENV['TOOLCHAIN']
    when 'msvc'
      raise "You don't have Visual Studio installed!" unless VisualStudio.available?
      vs = VisualStudio.latest
      puts "Defaulting to #{vs.name.pretty}."
      build_using_msvc(vs, configurations, platform, architectures)
    when /vs20(05|08|10|12|13|15)/
      vs = VisualStudio.find_by_name(ENV['TOOLCHAIN'])
      raise "You don't have #{VisualStudio::NAME_TO_PRETTY_NAME[ENV['TOOLCHAIN']]} installed." unless vs
      build_using_msvc(vs, configurations, platform, architectures)
    when 'gcc'
    when 'clang+llvm'
    else
      raise "Unknown or unsupported toolchain!"
    end
end

task :clean do
  puts "Cleaning..."
  FileUtils.rm_rf '_build'
end

def build_using_msvc(vs, configurations, platform, architectures)
  vc = vs.products[:c_and_cpp]
  platform_is_supported = vc.supports[:platforms].include?(platform)
  raise "#{vs.name.pretty} doesn't support '#{platform}'!" unless platform_is_supported
  sdk = vc.sdks[platform].first
  triplets = configurations.product([platform].product(architectures)).map(&:flatten)
  triplets.each do |configuration, platform, architecture|
    architecture_is_supported = vc.supports[:architectures].include?(architecture)
    raise "#{vs.name.pretty} doesn't support '#{architecture}'!" unless architecture_is_supported
    env = vc.environment(target: {platform: platform, architecture: architecture})
    suffix = [configuration, platform, Hash[ARCHITECTURES.zip(%w{32 64})][architecture]].join('_')
    case platform
      when :windows
        puts "~> Building luajit_#{suffix}.dll..."
        env = env.merge({'LJDLLNAME' => "luajit_#{suffix}.dll",
                         'LJLIBNAME' => "luajit_#{suffix}.lib"})
        system(env, "cmd.exe", "/c", "cd src & msvcbuild debug")
        puts "~> Copying artifacts to _build/"
        FileUtils.copy "src/luajit_#{suffix}.lib", "_build/lib/luajit_#{suffix}.lib"
        FileUtils.copy "src/luajit_#{suffix}.dll", "_build/bin/luajit_#{suffix}.dll"
        FileUtils.copy "src/luajit_#{suffix}.pdb", "_build/bin/luajit_#{suffix}.pdb" if File.exist? "src/luajit_#{suffix}.pdb"
        FileUtils.rm_f Dir.glob("src/**.{ilk,dll,lib,pdb,exe,obj,o,exp}")
        FileUtils.rm_f %w{src/lj_bcdef.h src/host/buildvm_arch.h}
      end
  end
end
