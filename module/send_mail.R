library(mailR)

send_result_mail <- function(recipient = NULL, result_link = NULL) {
  sender <- "result@pmet.simpleconstellation.com"

  # 设置电子邮件主题和内容
  subject <- "PMET result is ready!"
  body <- result_link



  send.mail(
    from = sender,
    to = recipient,
    subject = subject,
    body = body,
    smtp = list(
      host.name = "", # smtp 服务器主机名
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
