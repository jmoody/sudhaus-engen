# Records of processing activities

Record under Art. 30(1) GDPR for the website sudhaus-engen.de.

This is a translation for contributors. The authoritative version, and the one given to the supervisory authority, is [records-of-processing.de.md](records-of-processing.de.md). Changes must be carried into both versions.

This record is not published. It is produced to the supervisory authority on request (Art. 30(4) GDPR). It names only categories, recipients, and time limits, and holds no personal data itself.

Art. 30(5) GDPR exempts a controller with fewer than 250 employees where the processing is only occasional. The website is permanently reachable and therefore does not process occasionally, so the record is kept.

The published [Datenschutzerklärung](../internal/web/templates/datenschutz.html) describes the same processing.

## Controller

Joshua Moody, Lupfenstraße 1, 78234 Engen, Germany. Email: joshua.moody.de@gmail.com.

No data protection officer is appointed. Neither Art. 37(1) GDPR nor § 38(1) BDSG applies.

## Activity 1: serving the website

| Art. 30(1) item             | Content                                                                                                                                                                                                                                         |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Purpose                     | Operating the website and answering page requests                                                                                                                                                                                               |
| Legal basis                 | Art. 6(1)(f) GDPR. Legitimate interest: reliable and secure delivery of the website                                                                                                                                                             |
| Categories of data subjects | Visitors to the website                                                                                                                                                                                                                         |
| Categories of personal data | IP address and the remaining connection data of the HTTP request, processed solely to answer the request                                                                                                                                        |
| Categories of recipients    | Microsoft as hosting provider, processor under Art. 28 GDPR on the basis of the Microsoft Products and Services Data Protection Addendum (DPA), and at the same time independent controller for its own business operations under that same DPA |
| Third-country transfer      | United States (Microsoft Corporation), based on the adequacy decision for the EU-US Data Privacy Framework and on the Standard Contractual Clauses under Art. 46(2)(c) GDPR that form part of the DPA                                           |
| Time limits for erasure     | The application stores no request data. The operational logs in Azure Log Analytics hold no personal data and are deleted after 30 days. The DPA gives no retention period for the data Microsoft processes as an independent controller.       |

## Activity 2: email correspondence

| Art. 30(1) item             | Content                                                                                                            |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Purpose                     | Answering enquiries sent to the email address named in the Impressum                                               |
| Legal basis                 | Art. 6(1)(f) GDPR, or Art. 6(1)(b) GDPR where the enquiry relates to a contract                                    |
| Categories of data subjects | Senders of email                                                                                                   |
| Categories of personal data | Email address, name where given, and the content of the message and its attachments                                |
| Categories of recipients    | Google Ireland Limited as the mailbox provider                                                                     |
| Third-country transfer      | No transfer initiated by the controller. Whether the mailbox provider processes in third countries was not checked |
| Time limits for erasure     | Deletion once the enquiry is settled and no statutory retention duty applies                                       |

## Technical and organisational measures (Art. 30(1)(g) GDPR)

- Every connection to the website runs over TLS with a certificate managed by Azure Container Apps.
- The application writes no request data to a log. The rule is recorded in `.github/instructions/go.instructions.md` and in ADR 0001, and is checked in code review.
- The ingress table `ContainerAppHTTPLogs`, which carries client IP addresses, is not written to the Log Analytics workspace.
- The Log Analytics workspace sits in the Sweden Central region and deletes after 30 days.
- The site sets no cookie, embeds no analytics or tracking tool, and loads no resource from a third-party server.
- The Azure environment is administered by the controller alone, and the infrastructure is described and versioned in Terraform.

## Reservation

No lawyer has checked this reading. The retention period for the data Microsoft processes as an independent controller is not known.
