library(mailR)

# Define a function to send an email
# Arguments:
#   recipient: The recipient of the email
#   result_link: The result link of the email
send_result_mail <- function(recipient = NULL, result_link = NULL) {
  sender <- "result@pmet.simpleconstellation.com"

  subject <- "PMET result is ready!"
  body <- paste("Dear PMET user,\n\n\n",
                result_link,
                "The result will be kept in the server for a week, please download it as soon as possible.\n\n\n Thank you!", sep = "\n\n")

  send.mail(
    from = sender,
    to = recipient,
    subject = subject,
    body = body,
    smtp = list(
      host.name = "v095996.kasserver.com", # smtp 服务器主机名
      port = 587, # 默认端口
      user.name = "", # 用户名
      passwd = "", # 密码（授权码）
      ssl = TRUE
    ),
    authenticate = TRUE,
    send = TRUE,
    # attach.files = emailFile,
    encoding = "utf-8" # 编码
  )
}


# 获取命令行参数
args <- commandArgs(trailingOnly = TRUE)

# 提取收件人和结果链接
recipient <- args[1]
result_link <- args[2]

# 调用发送邮件函数
send_result_mail(recipient = recipient, result_link = result_link)
