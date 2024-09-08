library(dplyr)
library(emayili)

SendResultMail <- function(recipient = NULL, result_link = NULL) {

  email_credential <- readLines("data/email_credential.txt")
  EMAIL_USERNAME <- email_credential[1]
  EMAIL_PASSWORD <- email_credential[2]
  EMAIL_ADDRESS  <- email_credential[3]
  EMAIL_SERVER   <- email_credential[4]
  EMAIL_PORT     <- email_credential[5]

  sender <- EMAIL_ADDRESS

  if (is.null(result_link)) {
    subject <- "PMET is running, please be patient!"

    body <- paste(
      '<!DOCTYPE html>',
      '<html>',
      '<head>',
      '<meta charset="UTF-8">',
      '<style>',
      '  body { font-family: Arial, sans-serif; line-height: 1.8; background-color: #f4f4f4; margin: 0; padding: 0; }',
      '  .container { max-width: 600px; margin: 40px auto; padding: 20px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }',
      '  h2 { color: #333333; margin-bottom: 20px; }',
      '  p { font-size: 15px; color: #555555; margin: 10px 0; }',
      '  .note { font-size: 13px; color: #999999; margin-top: 20px; }',
      '  .footer { font-size: 13px; color: #888888; margin-top: 40px; text-align: center; }',
      '</style>',
      '</head>',
      '<body>',
      '<div class="container">',
      '<h2>Dear PMET User,</h2>',
      '<p>Your request is currently being processed. The results will be sent to your mailbox once PMET has completed its analysis.</p>',
      '<p class="note">If you do not receive the results within two days, please reply to this email for further assistance.</p>',
      '<p>Thank you for your patience!</p>',
      '<div class="footer">Best regards,<br/>The PMET Team</div>',
      '</div>',
      '</body>',
      '</html>',
      sep = ""
    )
  } else {
    subject <- "PMET result is ready!"
    body <- paste(
    '<!DOCTYPE html>',
    '<html>',
    '<head>',
    '<meta charset="UTF-8">',
    '<style>',
    '  body { font-family: Arial, sans-serif; line-height: 1.8; background-color: #f4f4f4; margin: 0; padding: 0; }',
    '  .container { max-width: 600px; margin: 40px auto; padding: 20px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }',
    '  h2 { color: #333333; margin-bottom: 20px; }',
    '  p { font-size: 15px; color: #555555; margin: 10px 0; }',
    '  .link { font-size: 16px; color: #1a73e8; text-decoration: none; word-wrap: break-word; }',
    '  .link:hover { text-decoration: underline; }',
    '  .note { font-size: 13px; color: #999999; margin-top: 20px; }',
    '  .footer { font-size: 13px; color: #888888; margin-top: 40px; text-align: center; }',
    '</style>',
    '</head>',
    '<body>',
    '<div class="container">',
    '<h2>Dear PMET User,</h2>',
    '<p>We are pleased to inform you that your results are ready. Please click the link below to access your results. If the link does not work, you can copy and paste it into your browser’s address bar.</p>',
    '<p><a href="', result_link, '" class="link">', result_link, '</a></p>',
    '<p class="note">Please note: The results will be available on the server for one week. We recommend downloading your results at your earliest convenience.</p>',
    '<p>If you have any questions or need further assistance, feel free to reply to this email.</p>',
    '<p>Thank you for using our services!</p>',
    '<div class="footer">Best regards,<br/>The PMET Team</div>',
    '</div>',
    '</body>',
    '</html>',
    sep = ""
  )

  }

  smtp <- emayili::server(
    host = EMAIL_SERVER,
    port = EMAIL_PORT,
    username = EMAIL_USERNAME,
    password = EMAIL_PASSWORD,
    use_ssl = TRUE
  )

  email <- emayili::envelope()
  email <- email %>% emayili::from(sender) %>% emayili::to(recipient) %>% emayili::subject(subject) %>% emayili::text(body)

  smtp(email, verbose = TRUE)
}

args <- commandArgs(trailingOnly = TRUE)

recipient <- args[1]
result_link <- if (length(args) >= 2) args[2] else NULL

SendResultMail(recipient = recipient, result_link = result_link)
