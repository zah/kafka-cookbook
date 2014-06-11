KafkaError = Class.new(StandardError)

def whyrun_supported?
  true
end

action :create do
  topic_name = @new_resource.name

  converge_by("Creating topic #{topic_name}") do
    create_cmd = %W{
      #{kafka_topics_sh}
        --create
        --zookeeper #{zookeeper_hosts}
        --replication-factor #{@new_resource.replication}
        --partitions #{@new_resource.partitions}
        --topic "#{topic_name}"}.join(" ")

    bash "create_kafka_topic"  do
      code create_cmd
      user "root"
      action :run
      not_if { topic_exists?(topic_name) }
    end
  end
end

action :update do
  topic_name = @new_resource.name
  converge_by("Updating configuration for topic #{topic_name}") do
    alter_cmd = %W{
      #{kafka_topics_sh}
        --alter
        --zookeeper #{zookeeper_hosts}
        --replication-factor #{@new_resource.replication}
        --partitions #{@new_resource.partitions}
        --topic "#{topic_name}"
    }.join(" ")

    bash "alter_kafka_topic" do
      code alter_cmd
      user "root"
      action :run
      only_if { topic_exists?(topic_name) }
    end
  end
end

action :delete do
  topic_name = @new_resource.name
  converge_by("Deleting topic #{topic_name}") do
    delete_cmd = %W{
      #{kafka_topics_sh}
        --delete
        --zookeeper #{zookeeper_hosts}
        --topic "#{topic_name}"
    }.join(" ")

    bash "delete_kafka_topic" do
      code delete_cmd
      user "root"
      action :run
      only_if { topic_exists?(topic_name) }
    end
  end
end

def topic_exists?(topic_name)
  list_cmd = %Q[#{kafka_topics_sh} --list --zookeeper #{zookeeper_hosts} | grep -i "#{topic_name}"]
  cmd = Mixlib::ShellOut.new(list_cmd)
  cmd.run_command
  cmd.exitstatus == 0
end

private

def kafka_bin_dir
  @kafka_bin or @kafka_bin = Path.join(node[:kafka][:install_dir], "bin")
end

def kafka_topics_sh
  @kafka_topics_sh or @kafka_topics_sh = Path.join(kafka_bin_dir, "kafka-topics.sh")
end

def zookeeper_hosts
  node[:kafka][:zookeeper][:connect] or
    raise KafkaError.new("Please specify node['kafka']['zookeeper']['connect']")
end
