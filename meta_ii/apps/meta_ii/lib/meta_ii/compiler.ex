defmodule MetaII.Compiler do
  def meta_ii_impl do
    """
    .SYNTAX PROGRAM

    OUT1 =
      '*1' .OUT('GN1') /
      '*2' .OUT('GN2') /
      '*' .OUT('CI') /
      .STRING .OUT('CL ' *)
    .,

    OUTPUT =
      ('.OUT' '(' $ OUT1 ')' /
       '.LABEL' .OUT('LB') OUT1)
      .OUT('OUT')
    .,

    EX3 =
      .ID .OUT ('CLL' *) /
      .STRING .OUT('TST' *) /
      '.ID' .OUT('ID') /
      '.NUMBER' .OUT('NUM') /
      '.STRING' .OUT('SR') /
      '(' EX1 ')' /
      '.EMPTY' .OUT('SET') /
      '$' .LABEL *1 EX3 .OUT('BT ' *1) .OUT('SET')
    .,

    EX2 =
      (EX3 .OUT('BF ' *1) /
       OUTPUT)
      $(EX3 .OUT('BE') /
        OUTPUT)
      .LABEL *1
    .,

    EX1 =
      EX2 $('/' .OUT('BT ' *1) EX2) .LABEL *1
    .,

    ST =
      .ID .LABEL * '=' EX1
      '.,' .OUT('R')
    .,

    PROGRAM =
      '.SYNTAX' .ID .OUT('ADR' *) $ ST
      '.END' .OUT('END')
    .,

    .END
    """
  end

  def meta_ii_machine do
    """
    ## .SYNTAX PROGRAM ##

            ADR PROGRAM         # PROGRAM > '.SYNTAX' .ID .OUT('ADR' *)

    ## OUT1 ##

            # "OUT1 ="
    OUT1                        # PROGRAM > ST > .ID .LABEL *

            # "'*1' .OUT('GN1') /"
            TST '*1'            #         > ST > EX1 > EX2 > EX3 > .STRING
            BF  A01             #                    > EX2
            CL  'GN1'           #                    > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                           > OUTPUT
    A01                         #                    > EX2
            BT  A02             #              > EX1$ > '/' > .OUT('BT ' *1)

            # "'*2' .OUT('GN2') /"
            TST '*2'            #                     > '/' > EX2 > EX3 > .STRING
            BF  A03             #                           > EX2
            CL  'GN2'           #                           > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                                  > OUTPUT
    A03                         #                           > EX2
            BT  A02             #              > EX1$ > '/' > .OUT('BT ' *1)

            # "'*' .OUT('CI') /"
            TST '*'             #                     > '/' > EX2 > EX3 > .STRING
            BF  A04             #                           > EX2
            CL  'CI'            #                           > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                                  > OUTPUT
    A04                         #                           > EX2
            BT  A02             #              > EX1$ > '/' > .OUT('BT ' *1)

            # ".STRING .OUT('CL ' *)"
            SR                  #                     > '/' > EX2 > EX3 > '.STRING'
            BF  A05             #                           > EX2
            CL  'CL '           #                           > EX2$ > OUTPUT > OUT1 > .STRING
            CI                  #                                    OUTPUT > OUT1 > '*'
            OUT                 #                                    OUTPUT
    A05                         #                           > EX2
    A02                         #              > EX1

            # ".,"
            R                   #         > ST


    ## OUTPUT ##

            # "OUTPUT ="
    OUTPUT                      # PROGRAM > ST > .ID .LABEL *

            # "('.OUT' '(' $ OUT1 ')' /"
            # "'.LABEL' .OUT('LB') OUT1)"
            # ".OUT('OUT')"
            # ".,"


    ## EX3 ##

            # "EX3 ="
    EX3                         # PROGRAM > ST > .ID .LABEL *

            # ".ID .OUT ('CLL' *) /"
            # ".STRING .OUT('TST' *) /"
            # "'.ID' .OUT('ID') /"
            # "'.NUMBER' .OUT('NUM') /"
            # "'.STRING' .OUT('SR') /"
            # "'(' EX1 ')' /"
            # "'.EMPTY' .OUT('SET') /"
            # "'$' .LABEL *1 EX3 .OUT('BT ' *1) .OUT('SET')"
            # ".,"


    ## EX2 ##

            # "EX2 ="
    EX2                         # PROGRAM > ST > .ID .LABEL *

            # "(EX3 .OUT('BF ' *1) /"
            # "OUTPUT)"
            # "$(EX3 .OUT('BE') /"
            # "OUTPUT)"
            # ".LABEL *1"
            # ".,"


    ## EX1 ##

            # "EX1 ="
    EX1                         # PROGRAM > ST > .ID .LABEL *
            # "EX2 $('/' .OUT('BT ' *1) EX2) .LABEL *1"
            # ".,"


    ## ST ##

      # TODO: replace _0, _1 with actual labels according to compiler
      #       ID generator state upon reaching this point.

            # "ST ="
    ST                          # PROGRAM > ST > .ID .LABEL *

            # ".ID .LABEL * '=' EX1"
            ID                  #         > ST > EX1 > EX2 > EX3 > '.ID'
            BF _01              #                    > EX2
            LB                  #                    > EX2$ > OUTPUT > '.LABEL' > OUT('LB')
            CI                  #                                    > '.LABEL' > OUT1 > '*'
            OUT                 #                           > OUTPUT
            TST '='             #                    > EX2$ > EX3 > .STRING
            BE                  #                    > EX2$
            CLL EX1             #                    > EX2$ > EX3 > .ID
            BE                  #                    > EX2$

            # "'.,' .OUT('R')"
            TST '.,'            #                    > EX2$ > EX3 > .STRING
            BE                  #                    > EX2$
            CL  'R'             #                    > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                           > OUTPUT
    _01                         #                    > EX2

    # another unused label; EX1$ never entered
    _02                         #              > EX1
            # ".,"
            R                   #         > ST > '.,'


    ## PROGRAM ##

            # "PROGRAM ="
    PROGRAM                     # PROGRAM > ST > .ID .LABEL *

            # "'.SYNTAX' .ID .OUT('ADR' *) $ ST"
            TST '.SYNTAX'       #         > ST > EX1 > EX2 > EX3 > .STRING
            BF  _03             #                    > EX2
            ID                  #                    > EX2$ > EX3 > '.ID'
            BE                  #                    > EX2$
            CL  'ADR'           #                    > EX2$ > OUTPUT > OUT1 > .STRING
            CI                  #                           > OUTPUT > OUT1 > '*'
            OUT                 #                           > OUTPUT
    _04                         #                    > EX2$ > EX3 > '$'
            CLL ST              #                                 > '$' > EX3 > .ID
            BT  _04             #                                 > '$' > .OUT('BT ' *1)
            SET                 #                                 > '$' > .OUT('SET')
            BE                  #                    > EX2$

            # "'.END' .OUT('END')"
            TST '.END'          #                    > EX2$ > EX3 > .STRING
            BE                  #                    > EX2$
            CL 'END'            #                    > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                           > OUTPUT
    _03                         #                    > EX2
    _05                         #              > EX1

            # ".,"
            R                   #         > ST


    ## .END ##

            # ".END"
            OUT 'END'           # PROGRAM > '.END' .OUT('END')
    """
    |> strip_comments
  end

  defp strip_comments(machine_src) do
    machine_src
    |> String.split("\n")
    |> Stream.map(fn line ->
      case Regex.run(~r/^([^#]*)?#.*$/, line) do
        [_, before_hash] -> before_hash |> String.trim_trailing
        nil -> line |> String.trim_trailing
      end
    end)
    |> Stream.filter(&(&1 != ""))
    |> Enum.join("\n")
  end
end
