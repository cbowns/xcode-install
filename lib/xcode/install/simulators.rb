require 'claide'

module XcodeInstall
  class Command
    class Simulators < Command
      self.command = 'simulators'
      self.summary = 'List or install iOS simulators.'

      def self.options
        [['--install=version', 'Install simulator with the given version.']].concat(super)
      end

      def initialize(argv)
        @installed_xcodes = Installer.new.installed_versions
        @install = argv.option('install')
        super
      end

      def run
        @install ? install : list
      end
    end

    :private

    def install
      filtered_simulators = @installed_xcodes.map(&:available_simulators).flatten.select do |sim|
        sim.version.to_s.start_with?(@install)
      end
      case filtered_simulators.count
      when 0
        puts "[!] No simulator matching #{@install} was found. Please specify a version from the following available simulators:".ansi.red
        list
        exit 1
      when 1
        simulator = filtered_simulators.first
        fail Informative, "#{simulator.name} is already installed." if simulator.installed?
        puts "Installing #{simulator.name} for Xcode #{simulator.xcode.bundle_version}..."
        simulator.install
      else
        puts "[!] More than one simulator matching #{@install} was found. Please specify the full version.".ansi.red
        filtered_simulators.each do |candidate|
          puts "Xcode #{candidate.xcode.bundle_version} (#{candidate.xcode.path})".ansi.green
          puts "xcode-install candidate --install=#{candidate.version}"
        end
        exit 1
      end
    end

    def list
      @installed_xcodes.each do |xcode|
        puts "Xcode #{xcode.version} (#{xcode.path})".ansi.green
        xcode.available_simulators.each do |simulator|
          puts simulator.to_s
        end
      end
    end
  end
end
