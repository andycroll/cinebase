# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'rake'
require 'rubygems/package'
require 'tmpdir'
require 'zlib'

module Cinebase
  module Vista
    # Defines package:native[platform] and package:all, which build platform
    # gems that bundle curl-impersonate for GuestToken. In a chain gem's
    # Rakefile: `Cinebase::Vista::PackageTask.new('odeon_uk.gemspec')`
    class PackageTask
      include Rake::DSL

      VERSION = '2.2.3'

      # Platform => [upstream asset target, SHA-256 of the v2.2.3 release asset]
      RELEASES = {
        'x86_64-linux-gnu' => ['x86_64-linux-gnu', 'ca7c8aae49e33260d3a2400db16c7737aaf04692d606a843502056b42990f989'],
        'aarch64-linux-gnu' => ['aarch64-linux-gnu', '5e71795b971f32be8f3d7785895f4dceb232f04414f5a067db266432a5b08657'],
        'arm64-darwin' => ['arm64-macos', '2569f4139460fcb301484d37938de91b1c220efd15487ee22a9db554262062fe'],
        'x86_64-darwin' => ['x86_64-macos', '4686806d59abea93866a917c3025a049ef3d7a3240de742ad66bd1a4d9890dc7']
      }.freeze

      # @param [String] gemspec path to the chain gem's gemspec
      # @param [String] root the chain gem's root directory
      def initialize(gemspec, root: Dir.pwd)
        @gemspec = gemspec
        @root = root
        define
      end

      private

      def define
        namespace :package do
          desc "Build a gem with bundled curl-impersonate #{VERSION} for the given platform"
          task :native, [:platform] do |_task, args|
            build(args.fetch(:platform))
          end

          desc 'Build all supported platform gems with bundled curl-impersonate'
          task :all do
            RELEASES.each_key { |platform| build(platform) }
          end
        end
      end

      def build(platform)
        target, digest = RELEASES.fetch(platform)
        asset = "curl-impersonate-v#{VERSION}.#{target}.tar.gz"
        url = "https://github.com/lexiforest/curl-impersonate/releases/download/v#{VERSION}/#{asset}"
        archive = File.join(@root, 'pkg', 'downloads', asset)
        download(url, archive)
        abort "SHA-256 mismatch for #{archive}; delete it and retry" unless Digest::SHA256.file(archive).hexdigest == digest

        spec = Gem::Specification.load(File.join(@root, @gemspec)).dup
        Dir.mktmpdir('vista-package') do |stage|
          spec.files.each do |file|
            destination = File.join(stage, file)
            FileUtils.mkdir_p(File.dirname(destination))
            FileUtils.cp(File.join(@root, file), destination)
          end
          vendor(archive, File.join(stage, 'vendor', 'curl-impersonate'), url, digest)

          Dir.chdir(stage) do
            spec.platform = Gem::Platform.new(platform)
            spec.files += Dir.glob('vendor/**/*').select { |file| File.file?(file) }
            Gem::Package.build(spec, false, false, File.join(@root, 'pkg', spec.file_name))
          end
        end
      end

      def download(url, archive)
        FileUtils.mkdir_p(File.dirname(archive))
        sh 'curl', '--fail', '--location', '--retry', '3', '--output', archive, url unless File.exist?(archive)
      end

      def vendor(archive, vendor, url, digest)
        Zlib::GzipReader.open(archive) do |gzip|
          Gem::Package::TarReader.new(gzip) do |tar|
            tar.each do |entry|
              next unless entry.file?

              relative = vendor_path(entry.full_name)
              next unless relative

              destination = File.join(vendor, relative)
              FileUtils.mkdir_p(File.dirname(destination))
              File.binwrite(destination, entry.read)
            end
          end
        end
        File.chmod(0o755, File.join(vendor, 'bin', 'curl-impersonate'))
        File.write(File.join(vendor, 'SOURCE'), <<~SOURCE)
          curl-impersonate #{VERSION}
          Binary: #{url}
          SHA-256: #{digest}
          Source and build instructions: https://github.com/lexiforest/curl-impersonate/tree/v#{VERSION}
          Redistribution notices: licenses/
        SOURCE
      end

      def vendor_path(name)
        if name == 'curl-impersonate'
          'bin/curl-impersonate'
        elsif name.start_with?('LICENSE') && File.basename(name) == name
          "licenses/#{name}"
        end
      end
    end
  end
end
