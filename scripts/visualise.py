import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
import os

OUTPUT = os.path.join(os.path.dirname(__file__), '..', 'output')

plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.size': 10,
    'axes.spines.top': False,
    'axes.spines.right': False,
    'figure.dpi': 150,
})

BLUE_DARK  = '#1a3a5c'
BLUE_MID   = '#2d6a9f'
BLUE_LIGHT = '#a8c8e8'
ORANGE     = '#e07b39'
RED        = '#c0392b'
GREEN      = '#27ae60'
GREY       = '#7f8c8d'


def save(fig, name):
    path = os.path.join(OUTPUT, name)
    fig.savefig(path, bbox_inches='tight')
    plt.close(fig)
    print(f'Saved {name}')


# --- Chart 1: HE access rate by IMD quintile ---
dep = pd.read_csv(os.path.join(OUTPUT, 'access_by_deprivation.csv'))
imd = dep[dep['analysis'].str.startswith('IMD access rate')].copy()
imd['quintile'] = imd['analysis'].str.replace('IMD access rate: ', '', regex=False)
imd['rate'] = imd['rates'].str.replace('%', '').astype(float)
imd = imd.sort_values('rate', ascending=False)
quintile_order = ['Q1 - Most deprived', 'Q2', 'Q3', 'Q4', 'Q5 - Least deprived']
imd = imd.set_index('quintile').reindex(quintile_order).reset_index()

fig, ax = plt.subplots(figsize=(8, 5))
colors = [BLUE_DARK, BLUE_MID, '#5a9fd4', BLUE_LIGHT, '#d0e8f8']
bars = ax.bar(imd['quintile'], imd['rate'], color=colors, width=0.6)
for bar, val in zip(bars, imd['rate']):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.3,
            f'{val:.1f}%', ha='center', va='bottom', fontsize=9)
ax.set_xlabel('Deprivation quintile (English IMD 2019)', labelpad=8)
ax.set_ylabel('HE access rate (%)')
ax.set_title('HE Access Rate by Deprivation Quintile\n(OfS AP sector data, most recent 2-year aggregate)', pad=10)
ax.set_ylim(0, imd['rate'].max() * 1.15)
save(fig, 'chart1_access_imd_quintile.png')


# --- Chart 2: Access rates by ethnic group (horizontal bar) ---
eth = pd.read_csv(os.path.join(OUTPUT, 'access_by_ethnicity.csv'))
eth = eth[~eth['ethnicity_minor'].isin(['Gypsy / Roma', 'Traveller of Irish Heritage'])].copy()
eth = eth.sort_values('progression_rate')

color_map = {
    'Above White British': GREEN,
    'Similar to White British': BLUE_MID,
    'Below White British': ORANGE,
}

fig, ax = plt.subplots(figsize=(10, 8))
colors_eth = [color_map[r] for r in eth['relative_position']]
bars = ax.barh(eth['ethnicity_minor'], eth['progression_rate'], color=colors_eth, height=0.7)
wb_rate = eth['white_british_rate'].iloc[0]
ax.axvline(wb_rate, color=BLUE_DARK, linestyle='--', linewidth=1.2, label=f'White British ({wb_rate:.1f}%)')
ax.set_xlabel('HE progression rate (%)')
ax.set_title('HE Access: Progression Rates by Ethnic Group\n(DfE Widening Participation, most recent year, England)', pad=10)
legend_handles = [
    mpatches.Patch(color=GREEN, label='Above White British'),
    mpatches.Patch(color=BLUE_MID, label='Similar to White British'),
    mpatches.Patch(color=ORANGE, label='Below White British'),
    plt.Line2D([0], [0], color=BLUE_DARK, linestyle='--', label=f'White British ({wb_rate:.1f}%)'),
]
ax.legend(handles=legend_handles, loc='lower right', fontsize=8)
ax.set_xlim(0, eth['progression_rate'].max() * 1.1)
save(fig, 'chart2_access_by_ethnicity.png')


# --- Chart 3: Attainment gap by ethnicity (grouped bar) ---
att = pd.read_csv(os.path.join(OUTPUT, 'attainment_gap_ethnicity.csv'))
att = att[att['ethnicity_code'] != 'White'].copy()

x = np.arange(len(att))
width = 0.35
fig, ax = plt.subplots(figsize=(9, 5))
bars1 = ax.bar(x - width/2, att['pct_good_honours'], width, label='Ethnic group', color=BLUE_MID)
bars2 = ax.bar(x + width/2, att['white_pct_good_honours'], width, label='White', color=BLUE_LIGHT)
for bar, val in zip(bars1, att['pct_good_honours']):
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
            f'{val:.1f}%', ha='center', va='bottom', fontsize=8)
for bar in bars2:
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
            f'{att["white_pct_good_honours"].iloc[0]:.1f}%', ha='center', va='bottom', fontsize=8)
ax.set_xticks(x)
ax.set_xticklabels(att['ethnicity_code'])
ax.set_ylabel('Good honours rate (%)')
ax.set_title('Degree Attainment Gap by Ethnicity\n(OfS AP sector data, full-time first degree, most recent 2-year aggregate)', pad=10)
ax.legend()
ax.set_ylim(0, 95)
save(fig, 'chart3_attainment_gap_ethnicity.png')


# --- Chart 4: Provider attainment vs deprivation (scatter) ---
prov_path = os.path.join(OUTPUT, 'attainment_by_provider.csv')
if os.path.exists(prov_path):
    prov = pd.read_csv(prov_path)
    fig, ax = plt.subplots(figsize=(9, 6))
    scatter = ax.scatter(
        prov['total_qualifiers'], prov['good_honours_rate'],
        c=prov['rank_highest'], cmap='RdYlGn_r', alpha=0.6, s=40
    )
    ax.axhline(prov['sector_average'].iloc[0], color=GREY, linestyle='--',
               linewidth=1, label=f'Sector avg ({prov["sector_average"].iloc[0]:.1f}%)')
    ax.set_xlabel('Number of qualifiers')
    ax.set_ylabel('Good honours rate (%)')
    ax.set_title('Provider Attainment: Good Honours Rate Distribution\n(OfS AP provider data, full-time first degree)', pad=10)
    ax.legend()
    plt.colorbar(scatter, ax=ax, label='Rank (1=highest)')
    save(fig, 'chart4_attainment_by_provider.png')
else:
    print('SKIP chart4_attainment_by_provider.png (data not ready)')


# --- Chart 5: Disability and attainment ---
dis = pd.read_csv(os.path.join(OUTPUT, 'attainment_disability.csv'))
dis_types = dis[dis['result_type'] == 'By disability type'].copy()
dis_types = dis_types.sort_values('good_honours_pct', ascending=True)
non_disabled_rate = dis[dis['group_label'] == 'Non-disabled']['good_honours_pct'].values[0]

fig, ax = plt.subplots(figsize=(9, 5))
colors_dis = [ORANGE if v < non_disabled_rate else BLUE_MID for v in dis_types['good_honours_pct']]
bars = ax.barh(dis_types['group_label'], dis_types['good_honours_pct'], color=colors_dis, height=0.6)
ax.axvline(non_disabled_rate, color=BLUE_DARK, linestyle='--', linewidth=1.2,
           label=f'Non-disabled ({non_disabled_rate:.1f}%)')
for bar, val in zip(bars, dis_types['good_honours_pct']):
    ax.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height()/2,
            f'{val:.1f}%', va='center', fontsize=9)
ax.set_xlabel('Good honours rate (%)')
ax.set_title('Degree Attainment by Disability Type\n(OfS AP sector data, full-time first degree)', pad=10)
ax.legend()
ax.set_xlim(0, 90)
save(fig, 'chart5_attainment_disability.png')


# --- Chart 6: Top subjects by FT employment rate (horizontal bar) ---
sal = pd.read_csv(os.path.join(OUTPUT, 'graduate_salary_by_subject.csv'))
sal = sal.sort_values('pct_ft_employed')
quartile_colors = {
    'Top quartile': GREEN,
    'Upper-middle quartile': BLUE_MID,
    'Lower-middle quartile': ORANGE,
    'Bottom quartile': RED,
}
subj_labels = sal['subject_area_of_degree'].str.replace(r'^\d+ ', '', regex=True)

fig, ax = plt.subplots(figsize=(10, 8))
colors_sal = [quartile_colors[q] for q in sal['employment_quartile']]
bars = ax.barh(subj_labels, sal['pct_ft_employed'], color=colors_sal, height=0.7)
for bar, val in zip(bars, sal['pct_ft_employed']):
    ax.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height()/2,
            f'{val:.0f}%', va='center', fontsize=8)
legend_handles = [mpatches.Patch(color=v, label=k) for k, v in quartile_colors.items()]
ax.legend(handles=legend_handles, loc='lower right', fontsize=8)
ax.set_xlabel('Full-time employment rate (%)')
ax.set_title('Graduate Full-time Employment Rate by Subject Area\n(HESA Graduate Outcomes 2022/23)', pad=10)
ax.set_xlim(0, 90)
save(fig, 'chart6_graduate_employment_by_subject.png')


# --- Chart 7: Graduate destinations stacked bar by subject ---
dest = pd.read_csv(os.path.join(OUTPUT, 'graduate_destinations.csv'))
dest = dest[dest['pct_any_employment'].notna() & (dest['total_known'].notna())].copy()
dest = dest[dest['subject_area_of_degree'] != 'Unknown subject']
dest = dest.sort_values('pct_any_employment', ascending=True)
subj_labels7 = dest['subject_area_of_degree'].str.replace(r'^\d+ ', '', regex=True)

dest['pct_pt_employed'] = (dest['pct_any_employment'] - dest['pct_ft_employed']).clip(lower=0)

fig, ax = plt.subplots(figsize=(11, 8))
left = np.zeros(len(dest))
categories = [
    ('pct_ft_employed',  'FT employment',  GREEN),
    ('pct_pt_employed',  'PT employment',  '#72c48a'),
    ('pct_any_study',    'Further study',  BLUE_MID),
    ('pct_unemployed',   'Unemployed',     RED),
]
for col, label, color in categories:
    vals = dest[col].fillna(0).values
    ax.barh(subj_labels7, vals, left=left, color=color, label=label, height=0.7)
    left += vals
ax.set_xlabel('Percentage of graduates (%)')
ax.set_title('Graduate Destinations 15 Months After Finishing\n(HESA Graduate Outcomes 2022/23, full-time first degree)', pad=10)
ax.legend(loc='lower right', fontsize=8)
save(fig, 'chart7_graduate_destinations.png')


# --- Chart 8: Employment rate by ethnicity and sex ---
emp = pd.read_csv(os.path.join(OUTPUT, 'employment_by_demographics.csv'))
emp_eth = (emp[emp['demographic_dimension'] == 'Ethnicity']
           .groupby('group_label')['employment_rate'].mean()
           .reset_index()
           .sort_values('employment_rate', ascending=False))
emp_sex = (emp[emp['demographic_dimension'] == 'Sex']
           .groupby('group_label')['employment_rate'].mean()
           .reset_index()
           .sort_values('employment_rate', ascending=False))

fig, axes = plt.subplots(1, 2, figsize=(12, 5))

ax = axes[0]
ax.bar(emp_eth['group_label'], emp_eth['employment_rate'], color=BLUE_MID, width=0.5)
ax.set_title('Average Employment Rate\nby Ethnicity', pad=8)
ax.set_ylabel('Employment rate (%)')
ax.set_ylim(0, 100)
for i, (_, row) in enumerate(emp_eth.iterrows()):
    ax.text(i, row['employment_rate'] + 0.5, f'{row["employment_rate"]:.1f}%',
            ha='center', va='bottom', fontsize=9)

ax = axes[1]
ax.bar(emp_sex['group_label'], emp_sex['employment_rate'], color=ORANGE, width=0.4)
ax.set_title('Average Employment Rate\nby Sex', pad=8)
ax.set_ylabel('Employment rate (%)')
ax.set_ylim(0, 100)
for i, (_, row) in enumerate(emp_sex.iterrows()):
    ax.text(i, row['employment_rate'] + 0.5, f'{row["employment_rate"]:.1f}%',
            ha='center', va='bottom', fontsize=9)

fig.suptitle('Graduate Employment by Ethnicity and Sex\n(OfS AP sector data, full-time, most recent 2-year aggregate)',
             fontsize=11, y=1.02)
save(fig, 'chart8_employment_by_demographics.png')


# --- Chart 9: Provider scorecard scatter (access vs outcomes) ---
scorecard_path = os.path.join(OUTPUT, 'provider_scorecard.csv')
if os.path.exists(scorecard_path):
    sc = pd.read_csv(scorecard_path)
    band_colors = {
        'Top 20%': GREEN,
        'Top 40%': BLUE_MID,
        'Middle': BLUE_LIGHT,
        'Lower 40%': ORANGE,
        'Bottom 20%': RED,
    }
    fig, ax = plt.subplots(figsize=(10, 7))
    for band, grp in sc.groupby('overall_band'):
        ax.scatter(grp['access_rate_pct'], grp['progression_pct'],
                   color=band_colors.get(band, GREY), label=band, alpha=0.7, s=50)
    ax.set_xlabel('IMD Q1 access rate (%)')
    ax.set_ylabel('Progression rate (%)')
    ax.set_title('Provider Scorecard: Access vs Progression Outcomes\n(OfS AP data, full-time undergraduates)', pad=10)
    ax.legend(title='Overall band', fontsize=8)
    save(fig, 'chart9_provider_scorecard.png')
else:
    print('SKIP chart9_provider_scorecard.png (data not ready)')

print('\nAll charts done.')
