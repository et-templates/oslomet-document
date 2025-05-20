// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


// Page margins are based on one of the official OsloMet templates. For now, the
// template is only optimised for Norwegian and the A4 format, not `us-letter`.

#let article(
  title: "Tittel",
  signature: true,
  show-date: true,
  authors: (),
  //affiliations: (),
  date: "",
  dateformat: "",
  abstract: "Dette er et sammendrag",
  abstract-title: none,
  cols: 1,
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  paper: "a4",
  lang: "nb",
  region: "NO",
  font: "Arial",
  fontsize: 10.5pt,
  singlequotes: ("‘", "’"),
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "Arial",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  link-color: rgb("#3282B8"),
  text-number-type: "old-style",
  text-number-width: "proportional",
  sectionnumbering: "1.1.1",
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,  
    header: context {
      if counter(page).get().first() == 1 [
        #place(
          dy: 20mm,
          image(
            "oslomet-logo-header.svg",
            height: 130%,
          )
        )
      ]
    },
    footer: context {
      if counter(page).get().first() == 1 [
        #place(
          dy: 2mm,
          image(
            "oslomet-logo-footer.svg",
            height: 7.5mm,
          ),
        )
      ] else [
        #set text(
          size: 8pt
        )
        \
        OsloMet – side
        #counter(page).display(
          (num, max) => [#num av #max],
          both: true
        )
      ]
    }
  )
  
  set par(justify: true)
  
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  
  set smartquote(
    quotes: (
      single: singlequotes,
      double: auto
    )
  )
  
  set heading(numbering: sectionnumbering)
  
  let heading_sizes = (fontsize) => {
    if fontsize == 12pt {
      (
        "title": 18pt,
        "h1": 18pt,
        "h2": 13pt,
        "h3": 12pt,
      )
    } else if fontsize == 11pt {
      (
        "title": 18pt,
        "h1": 16pt,
        "h2": 12pt,
        "h3": 11pt,
      )
    } else if fontsize == 10.5pt {
      (
        "title": 18pt,
        "h1": 15pt,
        "h2": 11pt,
        "h3": 10.5pt,
      )
    } else {
      (
        "title": 1.1em,
        "h1": 1.2em,
        "h2": fontsize,
        "h3": fontsize,
      )
    }
  }
  
  let sizes = heading_sizes(fontsize)
  
  show heading.where(level:1): it => block(
    text(
      size: sizes.h1,
      weight: "regular",
      style: "normal",
      it.body
    )
  )
  
  show heading.where(level:2): it => block(
    text(
      size: sizes.h2,
      weight: "bold",
      style: "normal",
      it.body
    )
  )
  
  show heading.where(level:3): it => block(
    text(
      size: sizes.h3,
      weight: "regular",
      style: "italic",
      it.body
    )
  )
  
  // utility function: go through all authors and check their affiliations
  // purpose is to group authors with the same affiliations
  // returns a dict with two keys:
  // "authors" (modified author array)
  // "affiliations": array with unique affiliations
  let parse_authors(authors) = {
    let affiliations = ()
    let parsed_authors = ()
    let corresponding = ()
    let pos = 0
    for author in authors {
      author.insert("affiliation_parsed", ())
      if "affiliation" in author {
        if type(author.affiliation) == str {
          author.at("affiliation") = (author.affiliation, )
        }
        for affiliation in author.affiliation {
          if affiliation not in affiliations {
            affiliations.push(affiliation)
          }
          pos = affiliations.position(a => a == affiliation)
          author.affiliation_parsed.push(pos)
        }
      } else {
        // if author has no affiliation, just use the same as the previous author
        author.affiliations_parsed.push(pos)
      }
      parsed_authors.push(author)
      if "corresponding" in author {
        if author.corresponding {
          corresponding = author
        }
      }
    }
    (authors: parsed_authors,
     affiliations: affiliations,
     corresponding: corresponding)
  }
  
  //let authors_parsed = parse_authors(authors)
  
  show link: set text(number-type: "lining", number-width: "tabular")
  
  show link: it => {
    set text(fill: link-color)
    it
  }
  
  v(14mm + 12pt)
  
  par(
    text(
      weight: "bold",
      size: sizes.title,
      title
    ),
  )
  
  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
  
  if signature == true {
    v(4em, weak: true)
  
    let datestring = if date != "" {
      [#date]
    }
    
    let signaturestring = if date != "" and show-date {
      [OsloMet – storbyuniversitetet, #datestring]
    } else {
      [OsloMet – storbyuniversitetet]
    }
    
    let count = authors.len()
    let ncols = calc.min(count, 3)
    figure(
      grid(
        columns: (1fr,) * ncols,
        row-gutter: 0.65em,//1.5em,
        //grid.header(repeat: false, signaturestring),
        grid.cell(align: left, colspan: ncols, signaturestring),
        ..authors.map(author =>
            align(left)[
              #author.name #if author.orcid != "" [#box(height: 10pt, baseline: 10%, link("https://orcid.org/" + author.orcid)[#image("orcid.svg")])] \
              #link("mailto:" + author.email.replace("\\",""))
            ]
        )
      )
    )
  }
}


// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates
#show: doc => article(
  title: [Uoffisiell mal for OsloMet-dokumenter],
  authors: (
    ( name: [Navn Navnesen],
      email: "navn.navnesen\@oslomet.no",
      orcid: ""
    ),
    ( name: [Eirik Tengesdal],
      email: "eirik.tengesdal\@oslomet.no",
      orcid: "0000-0003-0599-8925"
    ),
    ),
      date: datetime.today().display("[day].[month].[year]"),
    toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Innledning
<innledning>
Dette dokumentet fremviser en uoffisiell mal for OsloMet-dokumenter. Malen er per nå laget for å generere Typst-PDF-er med Quarto#footnote[Portering til en ren Typst-mal kan komme i fremtiden.];, og er basert på en offisiell OsloMet-mal for Word.#footnote[Det er noen forskjeller. For eksempel er topptekstlogoen venstrejustert så den er helt på linje med teksten under. I sidetallsnummereringen f.o.m. side 2 er det i tillegg til aktuelt sidetall lagt til \`av {maks antall sider}\`. Grunnet begrensninger i nåværende versjon av Typst er også margene konsistente på tvers av alle sider (i Word-malen er det ulik førsteside). Enkelte Quarto-elementer er også tatt med, for eksempel kan man på slutten av dokumentet velge å vise en signaturblokk som inneholder OsloMet-navnet, dato (valgfritt) og forfatterinformasjon.]

= Demonstrasjon av typografi:
<demonstrasjon-av-typografi>
= Overskrift, nivå 1
<overskrift-nivå-1>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis sagittis posuere ligula sit amet lacinia. Duis dignissim pellentesque magna, rhoncus congue sapien finibus mollis. Ut eu sem laoreet, vehicula ipsum in, convallis erat. Vestibulum magna sem, blandit pulvinar augue sit amet, auctor malesuada sapien. Nullam faucibus leo eget eros hendrerit, non laoreet ipsum lacinia. Curabitur cursus diam elit, non tempus ante volutpat a. Quisque hendrerit blandit purus non fringilla. Integer sit amet elit viverra ante dapibus semper. Vestibulum viverra rutrum enim, at luctus enim posuere eu. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

== Overskrift, nivå 2
<overskrift-nivå-2>
Nunc ac dignissim magna. Vestibulum vitae egestas elit. Proin feugiat leo quis ante condimentum, eu ornare mauris feugiat. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris cursus laoreet ex, dignissim bibendum est posuere iaculis. Suspendisse et maximus elit. In fringilla gravida ornare. Aenean id lectus pulvinar, sagittis felis nec, rutrum risus. Nam vel neque eu arcu blandit fringilla et in quam. Aliquam luctus est sit amet vestibulum eleifend. Phasellus elementum sagittis molestie. Proin tempor lorem arcu, at condimentum purus volutpat eu. Fusce et pellentesque ligula. Pellentesque id tellus at erat luctus fringilla. Suspendisse potenti.

Etiam maximus accumsan gravida. Maecenas at nunc dignissim, euismod enim ac, bibendum ipsum. Maecenas vehicula velit in nisl aliquet ultricies. Nam eget massa interdum, maximus arcu vel, pretium erat. Maecenas sit amet tempor purus, vitae aliquet nunc. Vivamus cursus urna velit, eleifend dictum magna laoreet ut. Duis eu erat mollis, blandit magna id, tincidunt ipsum. Integer massa nibh, commodo eu ex vel, venenatis efficitur ligula. Integer convallis lacus elit, maximus eleifend lacus ornare ac. Vestibulum scelerisque viverra urna id lacinia. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Aenean eget enim at diam bibendum tincidunt eu non purus. Nullam id magna ultrices, sodales metus viverra, tempus turpis.

=== Overskrift, nivå 3
<overskrift-nivå-3>
Duis ornare ex ac iaculis pretium. Maecenas sagittis odio id erat pharetra, sit amet consectetur quam sollicitudin. Vivamus pharetra quam purus, nec sagittis risus pretium at. Nullam feugiat, turpis ac accumsan interdum, sem tellus blandit neque, id vulputate diam quam semper nisl. Donec sit amet enim at neque porttitor aliquet. Phasellus facilisis nulla eget placerat eleifend. Vestibulum non egestas eros, eget lobortis ipsum. Nulla rutrum massa eget enim aliquam, id porttitor erat luctus. Nunc sagittis quis eros eu sagittis. Pellentesque dictum, erat at pellentesque sollicitudin, justo augue pulvinar metus, quis rutrum est mi nec felis. Vestibulum efficitur mi lorem, at elementum purus tincidunt a. Aliquam finibus enim magna, vitae pellentesque erat faucibus at. Nulla mauris tellus, imperdiet id lobortis et, dignissim condimentum ipsum. Morbi nulla orci, varius at aliquet sed, facilisis id tortor. Donec ut urna nisi.

Aenean placerat luctus tortor vitae molestie. Nulla at aliquet nulla. Sed efficitur tellus orci, sed fringilla lectus laoreet eget. Vivamus maximus quam sit amet arcu dignissim, sed accumsan massa ullamcorper. Sed iaculis tincidunt feugiat. Nulla in est at nunc ultricies dictum ut vitae nunc. Aenean convallis vel diam at malesuada. Suspendisse arcu libero, vehicula tempus ultrices a, placerat sit amet tortor. Sed dictum id nulla commodo mattis. Aliquam mollis, nunc eu tristique faucibus, purus lacus tincidunt nulla, ac pretium lorem nunc ut enim. Curabitur eget mattis nisl, vitae sodales augue. Nam felis massa, bibendum sit amet nulla vel, vulputate rutrum lacus. Aenean convallis odio pharetra nulla mattis consequat.

Ut ut condimentum augue, nec eleifend nisl. Sed facilisis egestas odio ac pretium. Pellentesque consequat magna sed venenatis sagittis. Vivamus feugiat lobortis magna vitae accumsan. Pellentesque euismod malesuada hendrerit. Ut non mauris non arcu condimentum sodales vitae vitae dolor. Nullam dapibus, velit eget lacinia rutrum, ipsum justo malesuada odio, et lobortis sapien magna vel lacus. Nulla purus neque, hendrerit non malesuada eget, mattis vel erat. Suspendisse potenti.
