# library(mailR)

# # Define a function to send an email
# # Arguments:
# #   recipient: The recipient of the email
# #   result_link: The result link of the email
# SendResultMail <- function(recipient = NULL, result_link = NULL) {
#   sender <- "result@pmet.simpleconstellation.com"

#   subject <- "PMET result is ready!"
#   body <- paste("Dear PMET user,\n\n\n",
#                 result_link,
#                 "The result will be kept in the server for a week, please download it as soon as possible.\n\n\n Thank you!", sep = "\n\n")

#   send.mail(
#     from = sender,
#     to = recipient,
#     subject = subject,
#     body = body,
#     smtp = list(
#       host.name = "v095996.kasserver.com",
#       port = 587,
#       user.name = "",
#       passwd = "",
#       ssl = TRUE
#     ),
#     authenticate = TRUE,
#     send = TRUE,
#     # attach.files = emailFile,
#     encoding = "utf-8"
#   )
# }


# args <- commandArgs(trailingOnly = TRUE)

# recipient <- args[1]
# result_link <- args[2]

# SendResultMail(recipient = recipient, result_link = result_link)

SendResultMail <- function(recipient = NULL, result_link = NULL) {

  email_credential <- readLines("data/email_credential.txt")
  EMAIL_USERNAME <- email_credential[1]
  EMAIL_PASSWORD <- email_credential[2]
  EMAIL_ADDRESS  <- email_credential[3]
  EMAIL_SERVER   <- email_credential[4]
  EMAIL_PORT     <- email_credential[5]

  sender <- EMAIL_ADDRESS

  subject <- "PMET result is ready!"
  body <- paste(
    "\n\n\nDear PMET user,\n\n\n",
    "Please copy and paste the link into a browser if cliking failed\n\n",
    result_link,
    "\nThe result will be kept in the server for a week, please download it as soon as possible.\n\n\n Thank you!",
    sep = "\n\n"
  )

  smtp <- server(
    host = EMAIL_SERVER,
    port = EMAIL_PORT,
    username = EMAIL_USERNAME,
    password = EMAIL_PASSWORD,
    use_ssl = TRUE
  )

  email <- envelope()
  email <- email %>% from(sender) %>% to(recipient) %>% subject(subject) %>% text(body)

  smtp(email, verbose = TRUE)
}

args <- commandArgs(trailingOnly = TRUE)

recipient <- args[1]
result_link <- args[2]

SendResultMail(recipient = recipient, result_link = result_link)
