# Create CPU Utilization Alarm

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {

  alarm_name = "high-cpu-alarm"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2

  metric_name = "CPUUtilization"

  namespace = "AWS/EC2"

  period = 300

  statistic = "Average"

  threshold = 25

  alarm_description = "Alarm when CPU exceeds 25 percent"

  dimensions = {

    InstanceId = aws_instance.monitor_server.id

  }

}