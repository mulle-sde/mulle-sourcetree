# shellcheck shell=bash
#
#   Copyright (c) 2024 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_SOURCETREE_GRAPHVIZ_SH='included'


sourcetree::graphviz::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} graphviz [options]

   Walk the sourcetree recursively and render every sourcetree config as an
   HTML table inside a Graphviz digraph. The table header shows the path of
   the repository and, if the config is not named "config", the config name
   in brackets. Each row is a node of that sourcetree.

   If a node is itself a sourcetree, an edge is drawn from that (inferior)
   row to the table of the other sourcetree. The edge is anchored to the
   row and labelled with the UUID of the connecting node. Nodes are
   deduplicated by UUID. Edges to embedded dependencies (no-build,no-share)
   use a round arrowhead (dot) in gray.

   Repositories must have been synced (mulle-sourcetree sync) for the walk
   to be complete.

Options:
   --svg|--png|--dot : output format (default: dot)
   --td|--lr         : graph direction (default: TD)
   -r|--recurse|--recursive : recurse through shared dependencies (default)
   --share           : operate on the shared/stash sourcetree
   --flat            : only the current sourcetree
   --no-dedupe       : do not deduplicate nodes by UUID
   --dedupe-mode <m> : dedupe mode for the walk (${GRAPHVIZ_DEDUPE_MODE})
   --max-level <n>   : maximum recursion depth
   -n|--nodetypes <t>: filter node types (default: ALL)

Environment:
   GRAPHVIZ_DEDUPE_MODE : dedupe mode for the walk (nodeline)
   GRAPHVIZ_NODETYPES   : filter node types (ALL)
   GRAPHVIZ_MAX_LEVEL   : maximum recursion depth
EOF
   exit 1
}


#
# prints one tab separated record per walked node:
#
#   1 ownerconfig   2 ownerroot  3 cfgname   4 address   5 nodetype
#   6 marks         7 uuid       8 url       9 childconfig
#  10 childroot    11 ischild
#
sourcetree::graphviz::r_sourcetree_root()
{
   local configfile="$1"

   r_dirname "${configfile}"   # the sourcetree config dir
   r_dirname "${RVAL}"         # etc
   r_dirname "${RVAL}"         # .mulle
   r_dirname "${RVAL}"         # sourcetree root
}


sourcetree::graphviz::visit()
{
   # log_entry "sourcetree::graphviz::visit"

   local osymbol
   local csymbol
   local candidate
   local owncf
   local childcf
   local ownroot
   local childroot
   local ischild

   ischild='NO'
   childcf=''
   childroot=''

   if [ "${WALK_LEVEL}" -eq 0 ]
   then
      osymbol=""
   else
      sourcetree::walk::r_symbol_for_address "${WALK_PARENT}"
      osymbol="${RVAL}"
   fi

   if sourcetree::walk::r_configfile "${osymbol}" "${WALK_DATASOURCE}"
   then
      owncf="${RVAL}"
   else
      owncf="${WALK_DATASOURCE}"
   fi

   sourcetree::graphviz::r_sourcetree_root "${owncf}"
   ownroot="${RVAL}"

   #
   # an inferior sourcetree is either relative to the config file
   # (recurse mode) or at the fetched location (share mode)
   #
   sourcetree::walk::r_symbol_for_address "${NODE_ADDRESS}"
   csymbol="${RVAL}"

   for candidate in "${WALK_DATASOURCE}${WALK_DESTINATION}/" "${NODE_FILENAME}/"
   do
      [ -z "${candidate}" ] && continue

      if sourcetree::walk::r_configfile "${csymbol}" "${candidate}"
      then
         childcf="${RVAL}"
         ischild='YES'
         break
      fi
   done

   if [ "${ischild}" = 'YES' ]
   then
      sourcetree::graphviz::r_sourcetree_root "${childcf}"
      childroot="${RVAL}"
   fi

   printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "${owncf}" \
      "${ownroot}" \
      "${SOURCETREE_CONFIG_NAME}" \
      "${NODE_ADDRESS}" \
      "${NODE_EVALED_NODETYPE:-${NODE_TYPE}}" \
      "${NODE_MARKS}" \
      "${NODE_UUID}" \
      "${NODE_EVALED_URL:-${NODE_URL}}" \
      "${childcf}" \
      "${childroot}" \
      "${ischild}"
}


#
# turn the records into a dot graph. Group rows by datasource (one HTML
# table per sourcetree), dedupe by uuid and link to inferior sourcetrees
#
sourcetree::graphviz::emit()
{
   local direction="$1"

   awk -F '\t' -v rankdir="${direction}" '
      function esc( s)
      {
         gsub( /&/, "\\&amp;", s)
         gsub( /</, "\\&lt;",  s)
         gsub( />/, "\\&gt;",  s)
         gsub( /"/, "\\&quot;", s)
         return s
      }

      function q( s)
      {
         return "\"" s "\""
      }

      # an embedded dependency carries both no-build and no-share
      function is_embedded( m,   k, n, a, has_no_build, has_no_share)
      {
         n = split( m, a, ",")
         for( k = 1; k <= n; k++)
         {
            if( a[k] == "no-build" )
               has_no_build = 1
            if( a[k] == "no-share" )
               has_no_share = 1
         }
         return( has_no_build && has_no_share )
      }

      BEGIN {
         n = 0
         nt = 0
      }

      {
         # deduplicate by uuid, keep the first one
         if( $7 != "")
         {
            if( seen[$7]++)
               next
         }

         i = ++n
         ds[i]     = $1
         addr[i]   = $4
         ntype[i]  = $5
         marks[i]  = $6
         uuid[i]   = $7
         url[i]    = $8
         cds[i]    = $9
         cflag[i]  = $11

         if( ! ($1 in tree))
         {
            tree[$1] = 1
            tid[$1] = "t" ++nt
         }
         if( tpath[$1] == "")
            tpath[$1] = $2
         if( tname[$1] == "")
            tname[$1] = $3

         # an inferior sourcetree may not produce any rows itself (empty
         # config), so remember its header info from the parent
         if( $11 == "YES" && $9 != "")
         {
            if( ! ($9 in tree))
            {
               tree[$9] = 1
               tid[$9] = "t" ++nt
            }
            if( tpath[$9] == "")
               tpath[$9] = $10
            if( tname[$9] == "")
               tname[$9] = $3
         }
      }

      function title( t,   s)
      {
         s = tpath[t]
         if( tname[t] != "" && tname[t] != "config")
            s = s " [" tname[t] "]"
         return s
      }

      END {
         printf "digraph sourcetree\n{\n"
         printf "   rankdir=%s;\n", rankdir
         printf "   node [ shape=plain ];\n\n"

         for( t in tree)
         {
            printf "   %s [ id=%s, label=<\n", q( tid[t]), q( tid[t])
            printf "<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\" CELLPADDING=\"4\">\n"
            printf "<TR><TD COLSPAN=\"5\" BGCOLOR=\"lightblue\"><B>%s</B></TD></TR>\n", esc( title( t))
            printf "<TR><TD><B>uuid</B></TD><TD><B>address</B></TD><TD><B>nodetype</B></TD><TD><B>marks</B></TD><TD><B>url</B></TD></TR>\n"

            for( i = 1; i <= n; i++)
            {
               if( ds[i] != t)
                  continue

               if( cflag[i] == "YES" && (cds[i] in tree))
                  a = sprintf( "<TD PORT=\"p%d\" HREF=\"#%s\">%s</TD>", i, tid[cds[i]], esc( addr[i]))
               else
                  a = sprintf( "<TD>%s</TD>", esc( addr[i]))

               printf "<TR><TD>%s</TD>%s<TD>%s</TD><TD>%s</TD><TD>%s</TD></TR>\n", \
                  esc( uuid[i]), a, esc( ntype[i]), esc( marks[i]), esc( url[i])
            }

            printf "</TABLE>> ];\n\n"
         }

         for( i = 1; i <= n; i++)
         {
            if( cflag[i] == "YES" && (cds[i] in tree) && cds[i] != ds[i])
            {
               attrs = "label=" q( esc( uuid[i]))
               if( is_embedded( marks[i]) )
                  attrs = attrs ", arrowhead=dot, color=gray40"
               printf "   %s:p%d -> %s [ %s ];\n", \
                  q( tid[ds[i]]), i, q( tid[cds[i]]), attrs
            }
         }

         printf "}\n"
      }
   '
}


sourcetree::graphviz::do_body()
{
   log_entry "sourcetree::graphviz::do_body" "$@"

   local mode="$1"
   local nodetypes="$2"

   WALK_PARENT="${WALK_PARENT:-.}"

   sourcetree::walk::walk_config_uuids "${nodetypes}" \
                                       "" \
                                       "" \
                                       "" \
                                       "${mode}" \
                                       "sourcetree::graphviz::visit"
}


sourcetree::graphviz::do()
{
   log_entry "sourcetree::graphviz::do" "$@"

   local mode="$1"
   local nodetypes="$2"
   local direction="$3"
   local records

   records="`sourcetree::graphviz::do_body "${mode}" "${nodetypes}"`" || return 1

   printf '%s\n' "${records}" | sourcetree::graphviz::emit "${direction}"
}


sourcetree::graphviz::cat_output()
{
   log_entry "sourcetree::graphviz::cat_output" "$@"

   local format="${1:-dot}"

   case "${format}" in
      dot)
         cat
      ;;

      *)
         DOT="${DOT:-`command -v dot`}"
         if [ -z "${DOT}" ]
         then
            fail "dot (graphviz) is not in PATH ($PATH)"
         fi
         "${DOT}" -T${format}
      ;;
   esac
}


sourcetree::graphviz::main()
{
   log_entry "sourcetree::graphviz::main" "$@"

   local OPTION_FORMAT="dot"
   local OPTION_DIRECTION="TD"
   local OPTION_MODE=""
   local OPTION_DEDUPE_MODE="${GRAPHVIZ_DEDUPE_MODE:-nodeline}"
   local OPTION_NODETYPES="${GRAPHVIZ_NODETYPES:-ALL}"
   local OPTION_MAX_LEVEL="${GRAPHVIZ_MAX_LEVEL:-}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::graphviz::usage
         ;;

         --svg|--png|--dot)
            OPTION_FORMAT="${1:2}"
         ;;

         --lr)
            OPTION_DIRECTION="LR"
         ;;

         --td)
            OPTION_DIRECTION="TD"
         ;;

         -r|--recurse|--recursive)
            OPTION_MODE="share"
         ;;

         --share)
            OPTION_MODE="share"
         ;;

         --flat)
            OPTION_MODE="flat"
         ;;

         --no-dedupe)
            OPTION_DEDUPE_MODE="none"
         ;;

         --dedupe-mode)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift
            OPTION_DEDUPE_MODE="$1"
         ;;

         --max-level)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift
            OPTION_MAX_LEVEL="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift
            OPTION_NODETYPES="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown graphviz option $1"
            sourcetree::graphviz::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree::graphviz::usage

   include "sourcetree::walk"

   local mode

   mode="${OPTION_MODE:-${SOURCETREE_MODE}}"

   case "${mode}" in
      flat)
      ;;

      *)
         r_comma_concat "${mode}" "pre-order"
         mode="${RVAL}"
      ;;
   esac

   r_comma_concat "${mode}" "dedupe-${OPTION_DEDUPE_MODE}"
   mode="${RVAL}"

   r_comma_concat "${mode}" "no-bequeath"
   mode="${RVAL}"

   r_comma_concat "${mode}" "eval-node"
   mode="${RVAL}"

   OPTION_MAX_WALK_LEVEL="${OPTION_MAX_LEVEL}"

   log_setting "GRAPHVIZ_DEDUPE_MODE : ${OPTION_DEDUPE_MODE}"
   log_setting "GRAPHVIZ_NODETYPES   : ${OPTION_NODETYPES}"
   log_setting "GRAPHVIZ_MAX_LEVEL   : ${OPTION_MAX_LEVEL}"
   log_setting "mode                 : ${mode}"

   sourcetree::graphviz::do "${mode}" "${OPTION_NODETYPES}" "${OPTION_DIRECTION}" \
   | sourcetree::graphviz::cat_output "${OPTION_FORMAT}"
}


sourcetree::graphviz::initialize()
{
   log_entry "sourcetree::graphviz::initialize"

   include "sourcetree::walk"
}

sourcetree::graphviz::initialize

: