let pretty_reporter ~formatter ?(src_width = 5) () =
  (* Thanks to: https://github.com/aantron/dream/blob/8140a600e4f9401e28f77fee3e4328abdc8246ef/src/server/log.ml#L110 *)
  let report src level ~over k user's_callback =
    let level_style, level =
      match level with
      | Logs.App -> (`Fg `White, "     ")
      | Logs.Error -> (`Fg `Red, "ERROR")
      | Logs.Warning -> (`Fg `Yellow, "WARN ")
      | Logs.Info -> (`Fg `Green, "INFO ")
      | Logs.Debug -> (`Fg `Blue, "DEBUG")
    in
    user's_callback @@ fun ?header ?tags format_and_arguments ->
    ignore header;
    ignore tags;
    let time =
      Ptime_clock.now () |> Ptime.to_rfc3339 ~frac_s:3 ~tz_offset_s:0
    in
    let source =
      let width = src_width in
      if Logs.Src.name src = Logs.Src.name Logs.default then
        String.make width ' '
      else
        let name = Logs.Src.name src in
        if String.length name > width then
          String.sub name (String.length name - width) width
        else String.make (width - String.length name) ' ' ^ name
    in
    let source_prefix, source =
      try
        let dot_index = String.rindex source '.' + 1 in
        ( String.sub source 0 dot_index,
          String.sub source dot_index (String.length source - dot_index) )
      with Not_found -> ("", source)
    in
    Format.kfprintf
      (fun _ ->
        over ();
        k ())
      formatter
      ("%a %a%s %a @[" ^^ format_and_arguments ^^ "@]@.")
      Fmt.(styled `Faint string)
      time
      Fmt.(styled `White string)
      source_prefix source
      Fmt.(styled level_style string)
      level
  in
  { Logs.report }

let setup_logs () =
  let formatter = Fmt.stdout in
  Fmt.set_style_renderer Fmt.stdout `Ansi_tty;
  Logs.set_reporter (pretty_reporter ~formatter ());
  Logs.set_level (Some Logs.Debug);
  ()
