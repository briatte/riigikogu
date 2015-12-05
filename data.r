bills = "data/bills.csv"
sponsors = "data/sponsors.csv"
r = "http://www.riigikogu.ee"

if (!file.exists(bills)) {

  b = data_frame()

  #
  # download bill lists
  #

  cat("Downloading bill indexes...\n")
  for (i in 13:11) {

    cat("Session", i)

    f = paste0("raw/bill-lists/bills-", i, ".html")
    if (!file.exists(f)) {
      download.file(paste0(r, "/?checked=eelnoud&s=&initiatedStartDate=&initiatedEndDate=&s=&mark=&membership=", i, "&leadingCommission=&responsibleMember=&activeDraftStage=&draftTypeCode=SE&initiator="),
                    f, mode = "wb", quiet = TRUE)
    }

    h = read_html(f) %>%
      html_nodes("#koikEl .pagination a") %>%
      html_attr("href") %>%
      unique

    cat(":", length(h), "pages")
    for (j in h) {

      f = paste0("raw/bill-lists/bills-", i, "-", str_extract(j, "\\d+"), ".html")
      if (!file.exists(f)) {
        download.file(paste0(r, "/", j), f, mode = "wb", quiet = TRUE)
      }
      cat(".")

      p = read_html(f)

      b = rbind(b, data_frame(
        legislature = i,
        session = html_nodes(p, "#koikEl .search-results-eelnoud td:nth-child(5)") %>%
          html_text,
        number = html_nodes(p, "#koikEl .search-results-eelnoud td:first-child") %>%
          html_text %>%
          str_extract("\\d+"),
        date = html_nodes(p, "#koikEl .search-results-eelnoud td:nth-child(4)") %>%
          html_text,
        # status = html_nodes(p, "#koikEl .search-results-eelnoud td:nth-child(3)") %>%
        #   html_text %>%
        #   str_replace("\\s+|\\\\n", ""),
        title = html_nodes(p, "#koikEl .search-results-eelnoud td:nth-child(2)") %>%
          html_text,
        url = html_nodes(p, "#koikEl .search-results-eelnoud td:nth-child(2) a") %>%
          html_attr("href")
      ))

    }
    cat("\n")

  }

  #
  # download bill pages
  #

  b$authors = NA
  b$links = NA

  cat("Downloading bills...\n")
  pb = txtProgressBar(0, nrow(b), style = 3)

  for (i in 1:nrow(b)) {

    f = paste0("raw/bill-pages/bill-", b$legislature[ i ], "-", b$number[ i ], ".html")
    # cat(sprintf("%3.0f", i), f)

    if (!file.exists(f)) {
      try(download.file(str_replace_all(b$url[ i ], "\\s", "%20"), f, mode = "wb", quiet = TRUE), silent = TRUE)
    }

    if (file.exists(f) && file.info(f)$size > 0) {

      p = read_html(f) %>%
        html_nodes(xpath = "//strong[contains(text(), 'Algataja')]/..")

      t = html_text(p) %>%
        str_replace_all("\\\n", "") %>%
        str_replace("(.*)Algataja:(.*)Algatatud:(.*)", "\\2") %>%
        str_trim

      # l. 13 has links, others do not
      a = html_nodes(p, xpath = "a[contains(@href, 'liikmed')]") %>% html_attr("href")

      # cat(":", 1 + str_count(t, ","), "sponsor(s):", t, "\n")
      b$authors[ i ] = str_replace_all(t, ",\\s?", ";")
      b$links[ i ] = unique(a) %>% paste0(collapse = ";")

    } else if (file.exists(f)) {
      file.remove(f)
    }

    setTxtProgressBar(pb, i)

  }

  b$n_a = str_count(b$authors, ";")
  b$n_l = str_count(b$links, ";")

  b$n_a[ is.na(b$n_a) ] = 0
  b$n_l[ b$n_l %in% c("", NA) ] = 0

  table(b$legislature, b$n_a > 1, exclude = NULL)
  write.csv(b, bills, row.names = FALSE)

}

b = read.csv(bills, stringsAsFactors = FALSE)

if (!file.exists(sponsors)) {

  #
  # download all sponsors from l. 11
  #

  f = "raw/mp-11.html"
  if (!file.exists(f)) {
    download.file(paste0(r, "/tutvustus-ja-ajalugu/riigikogu-ajalugu/xi-riigikogu-koosseis/juhatus-ja-liikmed/"),
                  f, mode = "wb", quiet = TRUE)
  }
  t = read_html(f) %>%
    html_nodes("#main.group.page table") %>%
    html_table(header = TRUE)

  # name
  n = str_extract(t[[1]][, 1], "(.*?)(\\n|$)") %>%
    str_replace("\\\n", "")

  # party
  p = str_replace(n, "(.*?)\\((.*?)\\)(.*)", "\\2")

  # manual corrections
  p[ n == "Robert Antropov" ] = "RE"
  p[ n == "Elle Kull" ] = "IRL"
  p[ n == "Leino Mägi" ] = "RE"
  p[ n == "Kadri Simson (Must)" ] = "K"
  p[ n == "Liina Tõnisson (SDE nimekirjas)" ] = "SDE"
  p[ n == "Mari-Ann Kelam asendusliige 06.06. 2009" ] = "IRL"
  p[ n == "Jaan Kundla (fraktsiooni mittekuuluv alates 22.04.2008))" ] = "K"
  p[ n == "Georg Pelisaar" ] = "K"
  p[ n == "Terje Trei" ] = "REF"
  p[ n == "Jaan Õunapuu" ] = "ERL"
  # n[ str_detect(p, "[a-z]") ]
  # table(p, exclude = NULL)

  n = str_replace(n, "(.*?)\\s\\((.*)", "\\1") %>%
    str_replace(" asendusliige(.*)", "") %>%
    str_trim

  # seniority
  m = t[[1]][, 5] %>%
    str_replace("─|–", "")
  m[ !nchar(m) ] = NA
  m[ !is.na(m) ] = 1 + str_count(m[ !is.na(m) ], ",")
  m[ is.na(m) ] = 0

  s = data_frame(
    legislature = 11,
    name = n,
    born = t[[1]][, 2] %>%
      str_extract("\\d{4}"),
    party = p,
    constituency = t[[1]][, 3] %>%
      str_extract("\\d+") %>%
      as.character, # sometimes NA (substitutes)
    nyears = 4 * as.integer(m),
    committees = t[[1]][, 4] %>%
      str_replace_all("\\d{4}", "") %>%
      str_extract_all("(\\w| )+?komisjon") %>%
      sapply(str_trim) %>%
      sapply(tolower) %>%
      sapply(paste0, collapse = ";"), # might be empty ("")
    photo = NA,
    url = NA
  )

  # few missing d.o.b.
  s$born[ s$name == "Robert Antropov" ] = 1965
  s$born[ s$name == "Mihkel Juhkami" ] = 1963 # from Googling
  s$born[ s$name == "Georg Pelisaar" ] = 1958

  #
  # download all sponsors from l. 12
  #

  f = "raw/mp-12.html"
  if (!file.exists(f)) {
    download.file(paste0(r, "/tutvustus-ja-ajalugu/riigikogu-ajalugu/xii-riigikogu-koosseis/juhatus-ja-liikmed/"),
                  f, mode = "wb", quiet = TRUE)
  }
  t = read_html(f) %>%
    html_nodes("#main table") %>%
    html_table(header = TRUE)

  # name
  n = str_extract(t[[1]][, 1], "(.*?)(\\n|$)") %>%
    str_replace("\\\n", "")

  # party
  p = str_replace(n, "(.*?)\\((.*?)\\)(.*)", "\\2")

  # manual corrections
  p[ grepl("^Etti Kagarov", n) ] = "SDE"
  p[ grepl("^Mihhail Lotman", n) ] = "IRL" # Echo Kreisman, substitute
  p[ grepl("^Jaanus Rahumägi", n) ] = "RE" # Lokk-Tramberg, substitute
  # n[ str_detect(p, "[a-z]") ]
  # table(p, exclude = NULL)
  p[ p == "KESK" ] = "K"

  n = str_replace(n, "(.*?)\\s\\((.*)", "\\1") %>%
    str_replace(" (asendusliige|astus|volitused)(.*)", "") %>%
    str_trim

  n[ n == "Etti Kagarov Jevgeni Ossinovksi" ] = "Etti Kagarov"

  # seniority
  m = t[[1]][, 5] %>%
    str_replace("─|–", "")
  m[ !nchar(m) ] = NA
  m[ !is.na(m) ] = 1 + str_count(m[ !is.na(m) ], ",")
  m[ is.na(m) ] = 0

  s = rbind(s, data_frame(
    legislature = 12,
    name = n,
    born = t[[1]][, 2] %>%
      str_extract("\\d{4}"),
    party = p,
    constituency = t[[1]][, 3] %>%
      str_extract("\\d+") %>%
      as.character, # sometimes NA (substitutes)
    nyears = 4 * as.integer(m),
    committees = t[[1]][, 4] %>%
      str_replace_all("\\d{4}|^(.*)\\\n", "") %>%
      str_extract_all("\\w+?(k|K){1,}") %>%
      sapply(unique) %>%
      sapply(paste0, collapse = ";") %>%
      toupper, # might be empty ("")
    photo = NA,
    url = NA
  ))

  # few missing d.o.b. (WP-ET)
  s$born[ s$name == "Mihhail Lotman" ] = 1952
  s$born[ s$name == "Jaanus Rahumägi" ] = 1963
  s$born[ s$name == "Ülle Rajasalu" ] = 1953
  s$born[ s$name == "Aivar Rosenberg" ] = 1962
  s$born[ s$name == "Vilja Savisaar-Toomast" ] = 1962
  s$born[ s$name == "Einar Vallbaum" ] = 1959

  #
  # check sponsor links for l. 13
  #

  for (i in which(b$legislature == 13)) {

    # find sponsors
    j = b$authors[ i ] %>% str_replace_all("\\s", "-") %>% str_split(";") %>% unlist
    j = j[ !grepl("fraktsioon|komisjon|Vabariigi-Valitsus", j) ]
    stopifnot(sum(!str_detect(b$links[ i ], j)) <= 1)
    j = j[ str_detect(b$links[ i ], j) ]

    # subset links
    if (length(j) > 0) {
      k = b$links[ i ] %>% str_split(";") %>% unlist
      k = k[ grepl(paste0(j, collapse = "|"), j) ]
      b$links[ i ] = paste0(k, collapse = ";")
    } else {
      b$links[ i ] = NA
    }

  }

  #
  # download all sponsors from l. 13
  #

  a = str_split(b$links[ b$legislature == 13 ], ";") %>% unlist %>% unique

  for (i in a[ !a %in% c("", NA) ]) {

    f = gsub("(.*)/(.*)", "raw/mp-pages/\\2.html", i)
    if (!file.exists(f)) {
      download.file(i, f, mode = "wb", quiet = TRUE)
    }
    h = read_html(f)

    # photo
    p = html_node(h, ".profile-photo img") %>% html_attr("src")
    f = paste0("photos/", basename(p))
    if (!file.exists(f)) {
      download.file(paste0(r, p), f, mode = "wb", quiet = TRUE)
    }

    # party
    f = html_nodes(h, ".profile-desc a") %>% html_attr("href")

    # mandate
    m = html_nodes(h, xpath = "//strong[contains(text(), 'Esinduskogud')]/..") %>%
      html_text %>%
      str_replace("(.*)Esinduskogud:(.*?)\\.(.*)", "\\2") %>%
      str_extract_all("(I|V|X)+") %>%
      unlist

    s = rbind(s, data_frame(
      legislature = 13,
      name = html_node(h, ".profile-photo img") %>%
        html_attr("alt"),
      born = html_nodes(h, xpath = "//strong[contains(text(), 'Sünniaeg')]/..") %>%
        html_text %>%
        str_extract("\\d{4}") %>%
        ifelse(length(.), ., NA),
      party = basename(f[ grepl("fraktsioon", f) ]),
      constituency = html_node(h, xpath = "//a[contains(@href, 'Constituency')]") %>%
        html_text %>%
        str_replace("\\\n", "") %>%
        str_trim,
      nyears = 4 * length(m[ m != "XIII" ]),
      committees = f[ grepl("komisjon", f) ] %>%
        basename %>%
        paste0(collapse = ";"),
      url = i,
      photo = p
    ))

  }

  # few missing d.o.b.
  s$born[ s$name == "Artur Talvik" ] = 1964
  s$born[ s$name == "Laine Randjärv" ] = 1964
  s$born[ s$name == "Maris Lauri" ] = 1966

  s$party[ s$party == "eesti-keskerakonna-fraktsioon" ] = "K"
  s$party[ s$party == "sotsiaaldemokraatliku-erakonna-fraktsioon" ] = "SDE"
  s$party[ s$party == "eesti-vabaerakonna-fraktsioon" ] = "EV"
  s$party[ s$party == "eesti-konservatiivse-rahvaerakonna-fraktsioon" ] = "EKRE"
  s$party[ s$party == "eesti-reformierakonna-fraktsioon" ] = "RE"
  s$party[ s$party == "isamaa-ja-res-publica-liidu-fraktsioon" ] = "IRL"

  # sponsor genders (imputed from first names)
  s$sex = sapply(s$name, strsplit, "\\s") %>% sapply(function(x) x[[1]])
  s$sex[ s$sex %in% c("Aadu", "Aare", "Ain", "Aivar", "Aleksei", "Andre", "Andrei", "Andres",
                      "Andrus", "Ants", "Arno", "Arto", "Artur", "Arvo", "Deniss", "Dmitri",
                      "Edgar", "Eerik-Niiles", "Eiki", "Einar", "Eldar", "Enn", "Erik", "Erki",
                      "Georg", "Hannes", "Hanno", "Harri", "Heimar", "Helir-Valdor", "Helmer", "Henn",
                      "Igor", "Imre", "Indrek", "Innar", "Ivari", "Jaak",
                      "Jaan", "Jaanus", "Janno", "Jevgeni", "Johannes", "Juhan", "Juku-Kalle", "Jürgen", "Jüri",
                      "Kajar", "Kalev", "Kalle", "Kalmer", "Kalvi", "Karel",
                      "Ken-Marti", "Kristen", "Kristjan", "Lauri", "Leino", "Lembit",
                      "Madis", "Mait", "Marek", "Margus", "Mark", "Marko", "Mart",
                      "Märt", "Martin", "Mati", "Meelis", "Mihhail", "Mihkel", "Neeme", "Nikolai",
                      "Ott", "Paul-Eerik", "Peep", "Peeter", "Priit",
                      "Rain", "Rainer", "Rait", "Raivo", "Rannar", "Rein", "Remo", "Robert",
                      "Siim", "Siim-Valmar", "Silver", "Sulev", "Sven",
                      "Taavi", "Tanel", "Tarmo", "Tiit", "Toivo", "Tõnis", "Tõnu", "Toomas", "Trivimi",
                      "Ülo", "Uno", "Urbo", "Urmas",
                      "Väino", "Valdo", "Valdur", "Valeri", "Viktor", "Villu", "Vladimir") ] = "M"
  s$sex[ s$sex %in% c("Anne", "Anneli", "Annely", "Barbi-Jenny",
                      "Elle", "Ene", "Erika", "Ester", "Etti", "Evelyn", "Heidy",
                      "Heljo", "Helle", "Helmen", "Inara", "Ivi",
                      "Kadri", "Kaia", "Kaja", "Katrin", "Keit", "Kersti", "Krista", "Kristiina", "Külliki",
                      "Laine", "Liina", "Liisa-Ly",
                      "Mai", "Mailis", "Maimu", "Maire", "Maret", "Mari-Ann", "Marianne", "Marika", "Maris",
                      "Nelli", "Olga", "Reet", "Siiri", "Siret", "Tatjana", "Terje", "Tiina",
                      "Ülle", "Urve", "Vilja", "Yana", "Yoko") ] = "F"

  # table(s$sex)
  # table(s$name[ nchar(s$sex) > 1 ])
  write.csv(s, sponsors, row.names = FALSE)

}

s = read.csv(sponsors, stringsAsFactors = FALSE)
