"""Build the small, original SVG illustrations used by the worship lessons."""

from pathlib import Path


OUT = Path(__file__).resolve().parents[1] / "assets/features/worship/illustrations"
OUT.mkdir(parents=True, exist_ok=True)

WUDU = {
    "intention": "heart",
    "wash_hands": "hands",
    "rinse_mouth": "mouth",
    "rinse_nose": "nose",
    "wash_face": "face",
    "wash_arms": "arms",
    "wipe_head_ears": "head",
    "wash_feet": "feet",
}


def wudu(name: str, focus: str) -> str:
    details = {
        "heart": '<path d="M470 212c-24-31-67 1 0 54 67-53 24-85 0-54Z" fill="#d8a948"/><path d="M470 274v22" stroke="#d8a948" stroke-width="7" stroke-linecap="round"/>',
        "hands": '<path d="M410 363v-49q0-12 9-12t9 12v-23q0-13 10-13t10 13v-20q0-13 10-13t10 13v24q2-12 12-10t7 18l-5 50q-3 25-31 27h-13q-25-2-28-26Z" fill="#efb88f" stroke="#d49670" stroke-width="5" stroke-linejoin="round"/><path d="M441 247v-18q0-11 10-11t10 11v18" fill="none" stroke="#91d8d0" stroke-width="8" stroke-linecap="round"/>',
        "mouth": '<path d="M433 331q37 22 74 0" fill="none" stroke="#bd765c" stroke-width="8" stroke-linecap="round"/><path d="M470 283v35" stroke="#82d9d1" stroke-width="8" stroke-linecap="round"/><path d="M449 345q21 16 42 0" fill="none" stroke="#82d9d1" stroke-width="6" stroke-linecap="round"/>',
        "nose": '<path d="M470 264v50q-2 12-13 14" fill="none" stroke="#d69470" stroke-width="8" stroke-linecap="round"/><path d="M453 327q18 5 29-7m-10-49v34" fill="none" stroke="#82d9d1" stroke-width="7" stroke-linecap="round"/><circle cx="464" cy="306" r="5" fill="#b9eeea"/>',
        "face": '<path d="M430 245q40-33 80 0l-3 70q-2 30-37 38-35-8-37-38Z" fill="#efb88f" stroke="#d49670" stroke-width="5"/><path d="M438 293q32 15 64 0M452 331l-8 24m42-24 8 24" fill="none" stroke="#81d9d1" stroke-width="7" stroke-linecap="round"/><path d="M421 284h-18m119 0h18" stroke="#d8a948" stroke-width="5" stroke-linecap="round"/>',
        "arms": '<path d="M414 280q-14 23-4 65l15 43q8 15 21 7t6-21l-12-39 4-42m38 0 4 42-12 39q-7 13 6 21t21-7l15-43q10-42-4-65" fill="#efb88f" stroke="#d49670" stroke-width="6" stroke-linejoin="round"/><path d="M402 327q68-20 136 0" fill="none" stroke="#81d9d1" stroke-width="8" stroke-linecap="round"/>',
        "head": '<path d="M415 257q55-45 110 0" fill="none" stroke="#81d9d1" stroke-width="10" stroke-linecap="round"/><path d="M414 256l-18-10m129 10 18-10" stroke="#d8a948" stroke-width="6" stroke-linecap="round"/><path d="M420 290h-18m118 0h18" stroke="#81d9d1" stroke-width="7" stroke-linecap="round"/>',
        "feet": '<path d="M430 322v32l-28 17q-13 9-1 18h57q10-5 4-18l-6-49m45 0v32l28 17q13 9 1 18h-57q-10-5-4-18l6-49" fill="#efb88f" stroke="#d49670" stroke-width="5" stroke-linejoin="round"/><path d="M412 378q18-14 38 0m61 0q18-14 38 0" fill="none" stroke="#81d9d1" stroke-width="7" stroke-linecap="round"/>',
    }
    is_face = focus in {"mouth", "nose", "face", "head"}
    head = '<circle cx="470" cy="224" r="51" fill="#efb88f"/><path d="M423 216q3-54 47-54t47 54q-19-17-47-14-29-2-47 14Z" fill="#075b4a"/><path d="M435 224h70" stroke="#bd8b68" stroke-width="3" stroke-dasharray="3 8"/>'
    body = '<path d="M424 274q46-23 92 0l19 174q-65 31-130 0Z" fill="#fffaf0" stroke="#e8dfcb" stroke-width="5"/><path d="M424 287q-18 13-22 66l-9 43q-3 17 10 18t19-15l18-47m76-65q18 13 22 66l9 43q3 17-10 18t-19-15l-18-47" fill="#fffaf0" stroke="#e8dfcb" stroke-width="5" stroke-linejoin="round"/>'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 620">
<rect x="12" y="12" width="936" height="596" rx="54" fill="#fbf5e5"/>
<circle cx="480" cy="310" r="230" fill="#cdece0"/>
<path d="M190 180Q190 66 480 70q286-1 290 110 2 60-47 96-50 40-101 1-59-48-142-48t-142 48q-51 39-101-1-49-36-47-96Z" fill="#075b4a"/>
<path d="M265 350h430v174H265z" fill="#e7d9bd"/><path d="M281 367h397v142H281z" fill="#f1e8d7"/>
<path d="M390 352v-18q0-10 11-10t11 10v18m44 0v-18q0-10 11-10t11 10v18m44 0v-18q0-10 11-10t11 10v18" fill="none" stroke="#c49a45" stroke-width="10" stroke-linecap="round"/>
<path d="M390 355h22m44 0h22m44 0h22" stroke="#c49a45" stroke-width="10" stroke-linecap="round"/>
<ellipse cx="471" cy="534" rx="125" ry="17" fill="#c9c0ae" opacity=".52"/>
{head}<path d="M427 267q43-13 86 0" fill="none" stroke="#e4d6c4" stroke-width="7"/>{body}
<circle cx="650" cy="407" r="113" fill="#fffaf0" stroke="#e0d5bd" stroke-width="7"/>
{details[focus]}
<path d="M88 475q30-29 60 0m-42 33q21-20 42 0" fill="none" stroke="#8fd7c8" stroke-width="8" stroke-linecap="round"/><circle cx="841" cy="172" r="13" fill="#d8a948"/>
</svg>'''


PRAYER = {
    "opening_takbir": "stand_hands",
    "standing_recitation": "stand_fold",
    "bowing": "bow",
    "rise_from_bowing": "stand_fold",
    "prostration": "prostrate",
    "sitting_between_prostrations": "sit",
    "second_prostration": "prostrate",
    "tashahhud": "sit",
    "taslim": "sit_turn",
}


def salah(name: str, pose: str) -> str:
    poses = {
        "stand_hands": '<circle cx="480" cy="190" r="42"/><path d="M438 238q42-17 84 0l31 169q-73 27-146 0Zm0 5-30 93 35 25 26-93m73-25 30 93-35 25-26-93"/><path d="M431 267l-28-25m126 25 28-25" fill="none" stroke="#efb88f" stroke-width="14" stroke-linecap="round"/>',
        "stand_fold": '<circle cx="480" cy="190" r="42"/><path d="M438 238q42-17 84 0l31 169q-73 27-146 0Zm0 5-30 93 35 25 26-93m73-25 30 93-35 25-26-93"/><path d="M435 266q45 90 90 0m-76 28q31 35 62 0" fill="none" stroke="#efb88f" stroke-width="14" stroke-linecap="round"/>',
        "bow": '<circle cx="535" cy="224" r="40"/><path d="M496 252q37-30 79 0l-39 99-109-18q-12-8-3-19l85-62m-61 61 13 85m82-80-1 80m-95 0h33m48 0h33"/><path d="M430 330h-48m165 0h45" stroke="#efb88f" stroke-width="15" stroke-linecap="round"/>',
        "prostrate": '<circle cx="563" cy="360" r="34"/><path d="M529 353q-63-25-105 10l-64 55 30 25 76-37 99 5 91 26 10-32-95-44-42-8m-142 32-53 3m110 51-17 35m87-30 20 30"/><path d="M348 447h39m-27 25h42" stroke="#efb88f" stroke-width="12" stroke-linecap="round"/>',
        "sit": '<circle cx="480" cy="210" r="40"/><path d="M442 252q38-17 76 0l13 91q-51 29-102 0Zm7 88q31 29 62 0l-4 50-64 5-25 28m94-83q-31 29-62 0l4 50 64 5 25 28"/><path d="M407 424h28m90 0h28" stroke="#efb88f" stroke-width="14" stroke-linecap="round"/>',
        "sit_turn": '<circle cx="480" cy="210" r="40"/><path d="M442 252q38-17 76 0l13 91q-51 29-102 0Zm7 88q31 29 62 0l-4 50-64 5-25 28m94-83q-31 29-62 0l4 50 64 5 25 28"/><path d="M503 226q57-4 82-44m-8 1 11-2-2 11" fill="none" stroke="#d8a948" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>',
    }
    figure = poses[pose]
    # All figures are faceless, modestly dressed, and drawn in the same three-quarter-free side view.
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 620">
<rect x="12" y="12" width="936" height="596" rx="54" fill="#fbf5e5"/>
<circle cx="480" cy="295" r="225" fill="#cdece0"/>
<path d="M190 190Q190 83 480 78q286-1 290 112 2 52-47 88-50 40-101 1-59-48-142-48t-142 48q-51 39-101-1-49-36-47-88Z" fill="#075b4a"/>
<ellipse cx="480" cy="532" rx="235" ry="37" fill="#d7c9a9"/><path d="M254 491q226 61 452 0" fill="none" stroke="#c49a45" stroke-width="6" opacity=".72"/>
<g fill="#fffaf0" stroke="#e7ddcc" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">{figure}</g>
<path d="M452 151q28-23 56 0v14h-56Z" fill="#fffaf0" stroke="#e7ddcc" stroke-width="4"/>
<circle cx="203" cy="416" r="13" fill="#d8a948"/><circle cx="756" cy="425" r="10" fill="#8fd7c8"/>
</svg>'''


for filename, focus in WUDU.items():
    (OUT / f"wudu_{filename}.svg").write_text(wudu(filename, focus), encoding="utf-8")

for filename, pose in PRAYER.items():
    (OUT / f"salah_{filename}.svg").write_text(salah(filename, pose), encoding="utf-8")

print(f"Created {len(WUDU) + len(PRAYER)} illustrations in {OUT}")
