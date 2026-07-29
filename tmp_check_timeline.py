import json
d = json.load(open(r'G:\flutter_quran_data\timeline\page554.json'))
s = [e for e in d['events'] if e['action'] == 'show']
for i, e in enumerate(s[:15]):
    print(f'{i}: word_id={e["word_id"]} time={e["time"]}')
print('...')
for i, e in enumerate(s[-5:]):
    print(f'{len(s)-5+i}: word_id={e["word_id"]} time={e["time"]}')
