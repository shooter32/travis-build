require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Scala do
  let(:shell)  { stub('shell', :execute => true, :export_line => true, :echo => true) }
  let(:config) { described_class::Config.new }
  let(:job)    { described_class.new(shell, Hashr.new(:repository => {
                                                        :slug => "owner/repo"
                                                      }), config) }

  describe 'config' do
    it 'defaults :scala to "2.9.2"' do
      config.scala.should == '2.9.2'
    end

    it 'defaults :jdk to "default"' do
      config.jdk.should == 'default'
    end
  end

  describe 'setup' do
    context "when JDK version is not explicitly specified and we have to use the default one" do
      it 'switches to the default JDK version' do
        shell.expects(:export_line).with("TRAVIS_JDK_VERSION=default").returns(true)
        shell.expects(:execute).with('jdk_switcher use default').returns(true)
        shell.expects(:execute).with('java -version')
        shell.expects(:execute).with('javac -version')
        job.setup
      end

      it 'exports the Scala version to use for the build and announces it, without any validation' do
        config.scala = '0.0.7' # version validity is not verified
        shell.expects(:export_line).with('TRAVIS_SCALA_VERSION=0.0.7')
        shell.expects(:echo).with('Using Scala 0.0.7')
        job.setup
      end
    end

    context "when JDK version IS explicitly specified" do
      let(:config) { described_class::Config.new(:jdk => "openjdk6") }

      it 'switches to the given JDK version' do
        shell.expects(:export_line).with("TRAVIS_JDK_VERSION=openjdk6").returns(true)
        shell.expects(:execute).with('jdk_switcher use openjdk6').returns(true)
        shell.expects(:execute).with('java -version')
        shell.expects(:execute).with('javac -version')
        job.setup
      end
    end
  end

  describe 'script' do
    context "when configured to use SBT 2.8.2" do
      it 'returns "sbt ++2.8.2 test"' do
        config.scala = '2.8.2'
        job.expects(:uses_sbt?).returns(true)
        job.send(:script).should == 'sbt ++2.8.2 test'
      end
    end

    context "when SBT is not used by the project" do
      it 'falls back to Maven' do
        job.expects(:uses_sbt?).returns(false)
        job.send(:script).should == 'mvn test'
      end
    end
  end
end
