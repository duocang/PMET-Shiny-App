library(mailR)

# Define a function to send an email
# Arguments:
#   recipient: The recipient of the email
#   result_link: The result link of the email
SendResultMail <- function(recipient = NULL, result_link = NULL) {
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
      host.name = "v095996.kasserver.com",
      port = 587,
      user.name = "",
      passwd = "",
      ssl = TRUE
    ),
    authenticate = TRUE,
    send = TRUE,
    # attach.files = emailFile,
    encoding = "utf-8"
  )
}


args <- commandArgs(trailingOnly = TRUE)

recipient <- args[1]
result_link <- args[2]

SendResultMail(recipient = recipient, result_link = result_link)
