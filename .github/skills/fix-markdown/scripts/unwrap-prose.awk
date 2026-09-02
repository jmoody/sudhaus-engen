# Joins hard-wrapped Markdown prose and list items back into single logical lines.
# A blank line, heading (#), table row (|), blockquote (>), list marker (- / * / + / 1.)
# or code fence (```) ends the current logical line. Continuation lines are trimmed and
# appended with a single space. Leading YAML frontmatter (a --- delimited block at the
# very top of the file), fenced code blocks, and tables pass through untouched.
function trim(s){ sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
function flush(   i,out){
  if(!inunit) return
  out=first
  for(i=1;i<=nc;i++) out=out " " cont[i]
  print out
  inunit=0; nc=0
}
BEGIN{ fence=0; fm=0 }
{
  line=$0
  if(NR==1 && line ~ /^---[ \t]*$/){ fm=1; print line; next }
  if(fm){ print line; if(line ~ /^(---|\.\.\.)[ \t]*$/) fm=0; next }
  if(line ~ /^[ \t]*```/){ flush(); print line; fence=!fence; next }
  if(fence){ print line; next }
  if(line ~ /^[ \t]*$/){ flush(); print line; next }
  if(line ~ /^#/ || line ~ /^\|/ || line ~ /^>/){ flush(); print line; next }
  if(line ~ /^[ \t]*[-*+] / || line ~ /^[ \t]*[0-9]+\. /){ flush(); first=line; inunit=1; nc=0; next }
  if(inunit){ cont[++nc]=trim(line) }
  else { first=line; inunit=1; nc=0 }
}
END{ flush() }
