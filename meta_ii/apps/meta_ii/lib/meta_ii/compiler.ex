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
      .ID .OUT('CLL' *) /
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
            R                   # PROGRAM > ST


    ## OUTPUT ##

            # "OUTPUT ="
    OUTPUT                      # PROGRAM > ST > .ID .LABEL *

            # "('.OUT' '(' $ OUT1 ')' /"
            TST '.OUT'          #         > ST > EX1 > EX2 > EX3 > '(' > EX1 > EX2 > EX3 > .STRING
            BF  A06             #                                            > EX2 > .OUT('BF ' *1)
            TST '('             #                                            > EX2$ > EX3 > .STRING
            BE                  #                                            > EX2$
    A07                         #                                            > EX2$ > EX3 > '$' > .LABEL *1
            CLL OUT1            #                                                         > '$' > EX3 > .ID
            BT  A07             #                                                         > '$' > .OUT('BT ' *1)
            SET                 #                                                         > '$' > .OUT('SET')
            BE                  #                                            > EX2$
            TST ')'             #                                            > EX2$ > EX3 > .STRING
            BE                  #                                            > EX2$
    A06                         #                                            > EX2
            BT  A08             #                                      > EX1$ > '/' > .OUT('BT ' *1)

            # "'.LABEL' .OUT('LB') OUT1)"
            TST '.LABEL'        #                                               '/' > EX2 > EX3 > .STRING
            BF  A09             #                                                   > EX2
            CL  'LB'            #                                                   > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                                                          > OUTPUT
            CLL OUT1            #                                                   > EX2$ > EX3 > .ID
            BE                  #                                                   > EX2$
    A09                         #                                                   > EX2
    A08                         #                                      > EX1
            TST ')'             #                          > EX3 > ')'
            BF  A10             #                    > EX2

            # ".OUT('OUT')"
            CL  'OUT'           #                    > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                           > OUTPUT
    A10                         #                    > EX2
    A11                         #              > EX1

            # ".,"
            R                   # PROGRAM > ST


    ## EX3 ##

            # "EX3 ="
    EX3                         # PROGRAM > ST > .ID .LABEL *

            # ".ID .OUT('CLL' *) /"
            ID                  #         > ST > EX1 > EX2 > EX3 > '.ID'
            BF  A12             #                    > EX2 > .OUT('BF ' *1)
            CL  'CLL'           #                    > EX2$ > OUTPUT > OUT1 > .STRING
            CI                  #                           > OUTPUT > OUT1 > '*'
            OUT                 #                           > OUTPUT
    A12                         #                    > EX2
            BT  A13             #              > EX1$ > .OUT('BT ' *1)

            # ".STRING .OUT('TST' *) /"
            SR                  #              > EX1$ > EX2 > EX3 > '.STRING'
            BF  A14             #                     > EX2 > .OUT('BF ' *1)
            CL  'TST'           #                     > EX2$ > OUTPUT > OUT1 > .STRING
            CI                  #                            > OUTPUT > OUT1 > '*'
            OUT                 #                            > OUTPUT
    A14                         #                     > EX2
            BT  A13             #              > EX1$ > .OUT('BT ' *1)

            # "'.ID' .OUT('ID') /"
            TST '.ID'           #              > EX1$ > EX2 > EX3 > .STRING
            BF  A15             #                     > EX2 > .OUT('BF ' *1)
            CL  'ID'            #                     > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                            > OUTPUT
    A15                         #                     > EX2
            BT  A13             #              > EX1$ > .OUT('BT ' *1)

            # "'.NUMBER' .OUT('NUM') /"
            TST '.NUMBER'       #              > EX1$ > EX2 > EX3 > .STRING
            BF  A16             #                     > EX2 > .OUT('BF ' *1)
            CL  'NUM'           #                     > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                            > OUTPUT
    A16                         #                     > EX2
            BT  A13             #              > EX1$ > .OUT('BT ' *1)

            # "'.STRING' .OUT('SR') /"
            TST '.STRING'       #              > EX1$ > EX2 > EX3 > .STRING
            BF  A17             #                     > EX2 > .OUT('BF ' *1)
            CL  'SR'            #                     > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                            > OUTPUT
    A17                         #                     > EX2
            BT  A13             #              > EX1$ > .OUT('BT ' *1)

            # "'(' EX1 ')' /"
            TST '('             #              > EX1$ > EX2 > EX3 > .STRING
            BF  A18             #                     > EX2 > .OUT('BF ' *1)
            CLL EX1             #                     > EX2$ > EX3 > .ID
            BE                  #                     > EX2$
            TST ')'             #                     > EX2$ > EX3 > .STRING
            BE                  #                     > EX2$
    A18                         #                     > EX2
            BT  A13             #              > EX1$ > .OUT('BT ' *1)

            # "'.EMPTY' .OUT('SET') /"
            TST '.EMPTY'        #              > EX1$ > EX2 > EX3 > .STRING
            BF  A19             #                     > EX2 > .OUT('BF ' *1)
            CL  'SET'           #                     > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                            > OUTPUT
    A19                         #                     > EX2
            BT  A13             #              > EX1$ > .OUT('BT ' *1)

            # "'$' .LABEL *1 EX3 .OUT('BT ' *1) .OUT('SET')"
            TST '$'             #              > EX1$ > EX2 > EX3 > .STRING
            BF  A20             #                     > EX2 > .OUT('BF ' *1)
    A21                         #                     > EX2$ > .LABEL *1
            CLL EX3             #                     > EX2$ > EX3 > .ID
            BE                  #                     > EX2$
            BT  A21             #                     > EX2$ > .OUT('BT ' *1)
            SET                 #                     > EX2$ > .OUT('SET')
    A20                         #                     > EX2
    A13                         #              > EX1

            # ".,"
            R                   # PROGRAM > ST


    ## EX2 ##

            # "EX2 ="
    EX2                         # PROGRAM > ST > .ID .LABEL *

            # "(EX3 .OUT('BF ' *1) /"
            CLL EX3             #         > ST > EX1 > EX2 > EX3 > '(' > EX1 > EX2 > EX3 > .ID
            BF  A22             #                                            > EX2 > .OUT('BF ' *1)
            BF  A23             #                                            > EX2$ > .OUT('BF ' *1)
    A22                         #                                            > EX2
            BT  A24             #                                      > EX1 > '/' > .OUT('BT ' *1)

            # "OUTPUT)"
            CLL OUTPUT          #                                              '/' > EX2 > EX3 > .ID
            BF  A25             #                                                  > EX2 > .OUT('BF ' *1)
    A25                         #                                                  > EX2
    A24                         #                                      > EX1
            BF  A26             #                    > EX2

            # "$(EX3 .OUT('BE') /"
    A27                         #                    > EX2$ > EX3 > '$' > LABEL *1
            CLL EX3             #                                 > '$' > EX3 > '(' > EX1 > EX2 > EX3 > .ID
            BF  A28             #                                                         > EX2 > .OUT('BF ' *1)
            CL  'BE'            #                                                         > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                                                         > EX2$ > OUTPUT
    A28                         #                                                         > EX2
            BT  A29             #                                                   > EX1$ > '/' > .OUT('BT ' *1)

            # "OUTPUT)"
            CLL OUTPUT          #                                                   > EX1$ > '/' > EX2 > EX3 > .ID
            BF  A30             #                                                   > EX1$ > '/' > EX2
    A30                         #                                                   > EX1$ > '/' > EX2
    A29                         #                                                   > EX1
            BT  A27             #                                 > '$' > .OUT('BT ' *1)
            SET                 #                           > EX3 > '$' > .OUT('SET')
            BE                  #                    > EX2$

            # ".LABEL *1"
            LB                  #                    > EX2$ > OUTPUT > '.LABEL' > .OUT('LB')
            GN1                 #                                    > '.LABEL' > OUT1 > '*1'
            OUT                 #                           > OUTPUT
            BE                  #                    > EX2$
    A26                         #                    > EX2
    A31                         #              > EX1

            # ".,"
            R                   # PROGRAM > ST


    ## EX1 ##

            # "EX1 ="
    EX1                         # PROGRAM > ST > .ID .LABEL *

            # "EX2 $('/' .OUT('BT ' *1) EX2) .LABEL *1"
            CLL EX2             #         > ST > EX1 > EX2 > EX3 > .ID
            BF  A32             #                    > EX2
    A33                         #                    > EX2$ > EX3 > '$' > .LABEL *1
            TST '/'             #                                 > '$' > EX3 > EX1 > EX2 > EX3 > .STRING
            BF  A34             #                                                   > EX2
            BT  A35             #                                                   > EX2$ > .OUT('BT ' *1)
            CLL EX2             #                                                   > EX2$ > EX3 > .ID
            BE                  #                                                   > EX2$
    A34                         #                                                   > EX2
    A35                         #                                             > EX1
            BT  A33             #                                 > '$' > OUT('BT ' *1)
            SET                 #                                 > '$' > OUT('SET')
            BE                  #                    > EX2$ > .OUT('BE')
            LB                  #                    > EX2$ > OUTPUT > '.LABEL' > .OUT('LB')
            GN1                 #                                      '.LABEL' > OUT1 > '*1'
            OUT                 #                           > OUTPUT
    A32                         #                    > EX2
    A36                         #              > EX1

            # ".,"
            R                   # PROGRAM > ST


    ## ST ##

      # TODO: replace _0, _1 with actual labels according to compiler
      #       ID generator state upon reaching this point.

            # "ST ="
    ST                          # PROGRAM > ST > .ID .LABEL *

            # ".ID .LABEL * '=' EX1"
            ID                  #         > ST > EX1 > EX2 > EX3 > '.ID'
            BF  A37             #                    > EX2
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
    A37                         #                    > EX2

    # another unused label; EX1$ never entered
    A38                         #              > EX1
            # ".,"
            R                   # PROGRAM > ST > '.,'


    ## PROGRAM ##

            # "PROGRAM ="
    PROGRAM                     # PROGRAM > ST > .ID .LABEL *

            # "'.SYNTAX' .ID .OUT('ADR' *) $ ST"
            TST '.SYNTAX'       #         > ST > EX1 > EX2 > EX3 > .STRING
            BF  A39             #                    > EX2
            ID                  #                    > EX2$ > EX3 > '.ID'
            BE                  #                    > EX2$
            CL  'ADR'           #                    > EX2$ > OUTPUT > OUT1 > .STRING
            CI                  #                           > OUTPUT > OUT1 > '*'
            OUT                 #                           > OUTPUT
    A40                         #                    > EX2$ > EX3 > '$'
            CLL ST              #                                 > '$' > EX3 > .ID
            BT  A40             #                                 > '$' > .OUT('BT ' *1)
            SET                 #                                 > '$' > .OUT('SET')
            BE                  #                    > EX2$

            # "'.END' .OUT('END')"
            TST '.END'          #                    > EX2$ > EX3 > .STRING
            BE                  #                    > EX2$
            CL 'END'            #                    > EX2$ > OUTPUT > OUT1 > .STRING
            OUT                 #                           > OUTPUT
    A39                         #                    > EX2
    A41                         #              > EX1

            # ".,"
            R                   # PROGRAM > ST


    ## .END ##

            # ".END"
            END                 # PROGRAM > '.END' .OUT('END')
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
