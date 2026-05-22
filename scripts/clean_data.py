import pandas as pd
import numpy as np
import os
import re
import warnings
warnings.filterwarnings('ignore')

RAW = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw')
PROCESSED = os.path.join(os.path.dirname(__file__), '..', 'data', 'processed')
os.makedirs(PROCESSED, exist_ok=True)

SUPPRESSION_MARKERS = ['[N/A]', '[DP]', '[DPH]', 'x', 'X', 'N/A', 'na', 'NA', '.', '..', '~']


def clean_colnames(df):
    df.columns = [
        re.sub(r'[^a-z0-9_]', '_', c.lower().strip()).strip('_')
        for c in df.columns
    ]
    df.columns = [re.sub(r'_+', '_', c) for c in df.columns]
    return df


def numeric_cols(df, exclude=None):
    exclude = exclude or []
    for col in df.columns:
        if col in exclude:
            continue
        if df[col].dtype == object:
            cleaned = df[col].replace(SUPPRESSION_MARKERS, np.nan)
            cleaned = cleaned.str.replace('%', '', regex=False).str.strip() if hasattr(cleaned, 'str') else cleaned
            try:
                df[col] = pd.to_numeric(cleaned, errors='coerce')
            except Exception:
                pass
    return df


def read_raw(fname, encoding='utf-8', **kwargs):
    path = os.path.join(RAW, fname)
    try:
        return pd.read_csv(path, encoding=encoding, low_memory=False, **kwargs)
    except UnicodeDecodeError:
        return pd.read_csv(path, encoding='latin-1', low_memory=False, **kwargs)


def save(df, name):
    out = os.path.join(PROCESSED, name)
    df.to_csv(out, index=False, encoding='utf-8')
    print(f'  Saved {name}: {df.shape[0]:,} rows x {df.shape[1]} cols')


# OfS Access and Participation - SECTOR level
print('Cleaning APData_SECTOR.csv ...')
df = read_raw('APData_SECTOR.csv')
df = clean_colnames(df)
id_cols = ['ukprn', 'provider_name', 'year_timeseries', 'academic_year',
           'lifecycle_stage', 'population', 'mode', 'level', 'type',
           'split_ind_type', 'split_ind_combination', 'split_ind1', 'split_ind2']
df = numeric_cols(df, exclude=id_cols)
save(df, 'ap_sector.csv')

# OfS Access and Participation - PROVIDER level (large file, read in chunks)
print('Cleaning APData_all.csv ...')
chunks = []
chunk_iter = pd.read_csv(
    os.path.join(RAW, 'APData_all.csv'),
    low_memory=False,
    chunksize=50000
)
for chunk in chunk_iter:
    chunk = clean_colnames(chunk)
    id_cols_p = ['ukprn', 'provider_name', 'year_timeseries', 'academic_year',
                 'lifecycle_stage', 'population', 'mode', 'level', 'type',
                 'split_ind_type', 'split_ind_combination', 'split_ind1', 'split_ind2']
    chunk = numeric_cols(chunk, exclude=id_cols_p)
    chunks.append(chunk)
df_all = pd.concat(chunks, ignore_index=True)
save(df_all, 'ap_providers.csv')

# DfE FSM data
print('Cleaning fsm.csv ...')
df = read_raw('fsm.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'region_code', 'region_name',
                                'old_la_code', 'new_la_code', 'la_name', 'fsm_status'])
save(df, 'fsm.csv')

print('Cleaning fsm_gap.csv ...')
df = read_raw('fsm_gap.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'region_code', 'region_name',
                                'old_la_code', 'new_la_code', 'la_name'])
save(df, 'fsm_gap.csv')

print('Cleaning fsm_sex_ethnicity.csv ...')
df = read_raw('fsm_sex_ethnicity.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'sex', 'fsm_status',
                                'ethnicity_major', 'ethnicity_minor'])
save(df, 'fsm_sex_ethnicity.csv')

print('Cleaning ethnicity.csv ...')
df = read_raw('ethnicity.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'region_code', 'region_name',
                                'old_la_code', 'new_la_code', 'la_name',
                                'ethnicity_major', 'ethnicity_minor'])
save(df, 'ethnicity.csv')

print('Cleaning all_characteristics.csv ...')
df = read_raw('all_characteristics.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'breakdown_topic', 'breakdown'])
save(df, 'all_characteristics.csv')

print('Cleaning sex.csv ...')
df = read_raw('sex.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'region_code', 'region_name',
                                'old_la_code', 'new_la_code', 'la_name', 'sex'])
save(df, 'sex.csv')

print('Cleaning sen.csv ...')
df = read_raw('sen.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'region_code', 'region_name',
                                'old_la_code', 'new_la_code', 'la_name', 'sen_status'])
save(df, 'sen.csv')

print('Cleaning school_type.csv ...')
df = read_raw('school_type.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'a_level_status', 'establishment_type'])
save(df, 'school_type.csv')

print('Cleaning school_type_gap.csv ...')
df = read_raw('school_type_gap.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'a_level_status'])
save(df, 'school_type_gap.csv')

print('Cleaning tariff_group.csv ...')
df = read_raw('tariff_group.csv')
df = clean_colnames(df)
df = numeric_cols(df, exclude=['time_identifier', 'geographic_level', 'country_code',
                                'country_name', 'provider_name', 'tariff_grouping'])
save(df, 'tariff_group.csv')

# HESA Graduate Outcomes (SB272) - header at row 14
hesa_go_id_cols = ['personal_characteristic_category_filter',
                   'personal_characteristic_category',
                   'activity', 'country_of_provider', 'permanent_address',
                   'provider_type', 'level_of_qualification_obtained',
                   'mode_of_former_study', 'interim_study', 'academic_year']

print('Cleaning figure-5-2022-23.csv (graduate outcomes by demographics) ...')
df = read_raw('figure-5-2022-23.csv', header=14)
df = clean_colnames(df)
df = numeric_cols(df, exclude=hesa_go_id_cols)
save(df, 'grad_outcomes_demographics.csv')

print('Cleaning figure-10-2022-23.csv (graduate outcomes by subject) ...')
df = read_raw('figure-10-2022-23.csv', header=14)
df = clean_colnames(df)
subj_id_cols = ['subject_area_of_degree', 'activity', 'country_of_provider',
                'provider_type', 'level_of_qualification_obtained',
                'mode_of_former_study', 'interim_study', 'academic_year']
df = numeric_cols(df, exclude=subj_id_cols)
save(df, 'grad_outcomes_subject.csv')

print('Cleaning figure-13-2022-23.csv (graduates by salary band) ...')
df = read_raw('figure-13-2022-23.csv', header=13, encoding='latin-1')
df = clean_colnames(df)
sal_id_cols = ['personal_characteristic_category_filter',
               'personal_characteristic_category',
               'salary_band', 'country_of_provider', 'permanent_address',
               'provider_type', 'level_of_qualification_obtained',
               'mode_of_former_study', 'work_population_marker', 'academic_year']
df = numeric_cols(df, exclude=sal_id_cols)
save(df, 'grad_salary_bands.csv')

print('Cleaning figure-4.csv (graduate activity multi-year) ...')
df = read_raw('figure-4.csv', header=18)
df = clean_colnames(df)
fig4_id = ['activity', 'permanent_address', 'country_of_provider', 'provider_type',
           'level_of_qualification_obtained', 'mode_of_former_study',
           'interim_study', 'academic_year']
df = numeric_cols(df, exclude=fig4_id)
save(df, 'grad_activity_all_years.csv')

# HESA Student Statistics (SB269) - header rows vary
print('Cleaning figure-5.csv (student enrolments by characteristics) ...')
df = read_raw('figure-5.csv', header=17)
df = clean_colnames(df)
enrol_id = ['category_marker', 'category', 'entrant_marker', 'level_of_study',
            'mode_of_study', 'permanent_address', 'country_of_he_provider', 'academic_year']
df = numeric_cols(df, exclude=enrol_id)
save(df, 'student_enrolments_characteristics.csv')

print('Cleaning figure-6.csv (student enrolments by WP markers) ...')
df = read_raw('figure-6.csv', header=17, encoding='latin-1')
df = clean_colnames(df)
wp_id = ['category_marker', 'category', 'country_of_he_provider',
         'entrant_marker', 'level_of_study', 'country_of_permanent_address', 'academic_year']
df = numeric_cols(df, exclude=wp_id)
save(df, 'student_enrolments_wp.csv')

print('Cleaning figure-13.csv (student enrolments by subject) ...')
df = read_raw('figure-13.csv', header=18)
df = clean_colnames(df)
subjenrol_id = ['cah_level_1', 'entrant_marker', 'level_of_study',
                'mode_of_study', 'country_of_he_provider', 'sex', 'academic_year']
df = numeric_cols(df, exclude=subjenrol_id)
save(df, 'student_enrolments_subject.csv')

print('\nAll files cleaned and saved to data/processed/')
