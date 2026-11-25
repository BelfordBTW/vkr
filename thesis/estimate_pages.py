# Грубая оценка числа страниц основной части (без рендера)
import docx, math, sys
from docx.oxml.ns import qn
d = docx.Document(sys.argv[1])
lines = figs = tbl = code = h1 = 0; main = True
for el in d.element.body:
    tag = el.tag.split('}')[1]
    t = ''.join(x.text or '' for x in el.iter(qn('w:t')))
    if tag == 'p' and t.startswith('ПРИЛОЖЕНИЕ А'): main = False
    if not main: continue
    if tag == 'p':
        if el.find('.//' + qn('w:drawing')) is not None: figs += 1; continue
        if el.find('.//' + qn('w:pageBreakBefore')) is not None or 'Heading1' in str(el.xml[:400]): h1 += 1
        if 'Courier New' in [r.get(qn('w:ascii')) for r in el.iter(qn('w:rFonts'))]: code += 1; continue
        lines += max(1, math.ceil(len(t) / 78))
    elif tag == 'tbl':
        for tr in el.iter(qn('w:tr')):
            tcs = tr.findall(qn('w:tc')); mx = 1
            for tc in tcs:
                ct = ''.join(x.text or '' for x in tc.iter(qn('w:t'))); mx = max(mx, math.ceil(len(ct) / max(8, 100 / len(tcs))))
            tbl += mx
est = lines / 29 + tbl / 48 + figs * 0.55 + code / 55 + 6
print(f'text {lines/29:.1f} tables {tbl/48:.1f} figs {figs*0.55:.1f} code {code/55:.1f} -> ~{est:.0f} pages (Введение..Литература)')
