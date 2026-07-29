import openpyxl
wb = openpyxl.load_workbook(r'G:\flutter_quran_data\annotation\a554.xlsx')
ws = wb['Mots']
rows = []
for row in ws.iter_rows(min_row=2, values_only=True):
    rows.append(row)
rows.sort(key=lambda r: (r[1], -r[3]))
print('Sorted words:')
for i, r in enumerate(rows[:10]):
    print(f'  {i}: id={r[5]} aya={r[9]}')
print('... indices 58-68:')
for i, r in enumerate(rows[58:68]):
    print(f'  {58+i}: id={r[5]} aya={r[9]}')
print('...')
for i, r in enumerate(rows[-10:]):
    print(f'  {len(rows)-10+i}: id={r[5]} aya={r[9]}')
print(f'Total: {len(rows)} words')
