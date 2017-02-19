require 'active_support'
require 'active_support/core_ext'

require 'fileutils'

TOOLCHAINS = %w{msvc gcc clang}

PLATFORMS = %w{windows mac linux}
ARCHITECTURES = %w{x86 x86_64}
CONFIGURATIONS = %w{debug development release}

SUFFIXES = {
  'x86' => '32',
  'x86_64' => '64'
}

module Defaults
  def self.toolchain
    case self.platform
      when "windows"
        "msvc"
      when "mac"
        "clang"
      when "linux"
        "gcc"
    end
  end

  def self.platform
    case RbConfig::CONFIG["host_os"]
      when /mswin|windows|mingw|cygwin/i
        "windows"
      when /darwin/i
        "mac"
      when /linux/i
        "linux"
    end
  end

  def self.architectures
    %w{x86 x86_64}
  end

  def self.configurations
    %w{debug development release}
  end
end

# TODO(mtwilliams): Prase `toolchain` to allow `toolchain@version`.

task :build, [:toolchain, :platform, :architectures, :configurations] do |t, args|
  args.with_defaults(
    :toolchain => Defaults.toolchain,
    :platform => Defaults.platform,
    :architectures => Defaults.architectures,
    :configurations => Defaults.configurations)

  toolchain = args[:toolchain].inquiry
  platform = args[:platform].inquiry
  architectures = args[:architectures].map(&:inquiry)
  configurations = args[:configurations].map(&:inquiry)

  raise "Unknown or unsupported platform!" unless PLATFORMS.include?(platform)
  raise "Unknown architecture!" unless architectures.all? {|arch| ARCHITECTURES.include?(arch)}
  raise "Unknown configuration!" unless configurations.all? {|config| CONFIGURATIONS.include?(config)}

  matrix = [platform].product(architectures).product(configurations).map(&:flatten)

  FileUtils.mkdir_p ['_build/bin', '_build/lib']

  if toolchain.msvc?
    require 'visual_studio'

    raise "Can't find VisualStudio!" unless VisualStudio.available?

    vs = VisualStudio.latest
    vc = vs.products[:c_and_cpp]

    matrix.each_with_index do |triplet, build|
      platform, architecture, configuration = *triplet

      name = [configuration, platform, architecture]
         .map { |component| SUFFIXES.fetch(component, component) }
         .join('_')

      platform_is_supported = vc.supports[:platforms].include?(platform)
      architecture_is_supported = vc.supports[:architectures].include?(architecture)

      raise "Your install of #{vc.name.pretty} doesn't support #{platform}." unless platform_is_supported
      raise "Your install of #{vc.name.pretty} doesn't support #{architecture}." unless architecture_is_supported

      sdk = vc.sdks[platform].first
      env = vc.environment(target: {platform: platform, architecture: architecture})

      case platform
        when :windows
          puts format("[%-2d/%2d] Building for `%s`...", build+1, matrix.length+1, name)

          env = env.merge({'LJDLLNAME' => "luajit_#{name}.dll",
                           'LJLIBNAME' => "luajit_#{name}.lib"})

          puts " ~> Building #{name}"
          success = system(env, "cmd.exe", "/c", "cd src & msvcbuild debug")
          raise "Failed!" unless success

          puts "~> Moving artifacts to `_build/`"
          FileUtils.move "src/luajit_#{name}.lib", "_build/lib/luajit_#{name}.lib"
          FileUtils.move "src/luajit_#{name}.dll", "_build/bin/luajit_#{name}.dll"
          FileUtils.move "src/luajit_#{name}.pdb", "_build/bin/luajit_#{name}.pdb" if File.exist? "src/luajit_#{suffix}.pdb"

          puts "~> Deleting intermediates"
          FileUtils.rm_f Dir.glob("src/**.{ilk,dll,lib,pdb,exe,obj,o,exp}")
          FileUtils.rm_f %w{src/lj_bcdef.h src/host/buildvm_arch.h}
        end
    end
  elsif toolchain.clang? or toolchain.gcc?
    matrix.each_with_index do |triplet, build|
      platform, architecture, configuration = *triplet

      name = [configuration, platform, architecture]
               .map { |component| SUFFIXES.fetch(component, component) }
               .join('_')

      flags_for_architecture = {'x86' => '-m32', 'x86_64' => '-m64'}[architecture]

      env = {
        'MACOSX_DEPLOYMENT_TARGET' => '10.9',
        'CC' => "#{toolchain} #{flags_for_architecture}",
        'CFLAGS' => '-g',
        'LUAJIT_O' => "luajit_#{name}.o",
        'LUAJIT_A' => "libluajit_#{name}.a",
        'LUAJIT_SO' => "libluajit_#{name}.so",
        'LUAJIT_T' => "luajit_#{name}"
      }

      puts format("[%-2d/%2d] Building for `%s`...", build+1, matrix.length+1, name)

      puts " ~> Building #{name}"
      success = system(ENV.to_h.merge(env), "cd src; make")
      raise "Failed!" unless success

      puts "~> Moving artifacts to `_build/`"
      FileUtils.move "src/#{env['LUAJIT_A']}", "_build/lib/#{env['LUAJIT_A']}"
      FileUtils.move "src/#{env['LUAJIT_SO']}", "_build/bin/#{env['LUAJIT_SO']}"
      FileUtils.move "src/#{env['LUAJIT_T']}", "_build/bin/#{env['LUAJIT_T']}"

      puts "~> Cleaning up"
      success = system(ENV.to_h.merge(env), "cd src; make clean")
      raise "Failed!" unless success
    end
  else
    raise "Unsupported toolchain!"
  end
end

task :clean do
  FileUtils.rm_rf '_build'
end
