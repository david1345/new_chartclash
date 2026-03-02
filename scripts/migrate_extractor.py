import sys
import re
import json
import base64
from datetime import datetime

def parse_dump(filename):
    tables = {}
    current_table = None
    collecting = False
    
    # regex for COPY public.name (cols) FROM stdin;
    # Adjusted to allow leading text like "TABLE DATA O"
    copy_re = re.compile(r'COPY ([\w.]+) \((.*?)\) FROM stdin;', re.IGNORECASE)
    
    print(f"Opening {filename} for parsing...")
    with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            if 'COPY ' in line and ' FROM stdin;' in line:
                match = copy_re.search(line)
                if match:
                    current_table = match.group(1)
                    columns = [c.strip() for c in match.group(2).split(',')]
                    tables[current_table] = {'columns': columns, 'data': []}
                    collecting = True
                    print(f"Started collecting table: {current_table}")
                    continue
            
            if collecting:
                if line.startswith('\\.'):
                    print(f"Finished collecting table: {current_table} ({len(tables[current_table]['data'])} rows)")
                    collecting = False
                    current_table = None
                    continue
                
                # Split by tab
                row_data = line.strip('\n').split('\t')
                if current_table:
                    # Robust check: allow slight column mismatch if needed, but usually it should match
                    if len(row_data) == len(tables[current_table]['columns']):
                        row_data = [None if x == '\\N' else x for x in row_data]
                        tables[current_table]['data'].append(row_data)
                    
    return tables

def main():
    dump_file = 'vibe_prod_full.sql'
    print(f"Reading {dump_file}...")
    tables = parse_dump(dump_file)
    
    for table_name, detail in tables.items():
        print(f"Found table: {table_name} with {len(detail['data'])} rows")
        
    # Standardize data for Migration
    # 1. Users
    if 'auth.users' in tables:
        users = []
        cols = tables['auth.users']['columns']
        for row in tables['auth.users']['data']:
            user_dict = dict(zip(cols, row))
            users.append(user_dict)
        
        with open('migrate_users.json', 'w') as f:
            json.dump(users, f, indent=2)
        print(f"Exported {len(users)} users to migrate_users.json")

    # 2. Profiles
    if 'public.profiles' in tables:
        profiles = []
        cols = tables['public.profiles']['columns']
        for row in tables['public.profiles']['data']:
            profiles.append(dict(zip(cols, row)))
            
        with open('migrate_profiles.json', 'w') as f:
            json.dump(profiles, f, indent=2)
        print(f"Exported {len(profiles)} profiles to migrate_profiles.json")

    # 3. Predictions
    if 'public.predictions' in tables:
        predictions = []
        cols = tables['public.predictions']['columns']
        for row in tables['public.predictions']['data']:
            predictions.append(dict(zip(cols, row)))
            
        with open('migrate_predictions.json', 'w') as f:
            json.dump(predictions, f, indent=2)
        print(f"Exported {len(predictions)} predictions to migrate_predictions.json")

    # 4. Notifications
    if 'public.notifications' in tables:
        notifications = []
        cols = tables['public.notifications']['columns']
        for row in tables['public.notifications']['data']:
            notifications.append(dict(zip(cols, row)))
        with open('migrate_notifications.json', 'w') as f:
            json.dump(notifications, f, indent=2)
        print(f"Exported {len(notifications)} notifications to migrate_notifications.json")

    # 5. Activity Logs
    if 'public.activity_logs' in tables:
        logs = []
        cols = tables['public.activity_logs']['columns']
        for row in tables['public.activity_logs']['data']:
            logs.append(dict(zip(cols, row)))
        with open('migrate_activity_logs.json', 'w') as f:
            json.dump(logs, f, indent=2)
        print(f"Exported {len(logs)} activity logs to migrate_activity_logs.json")

if __name__ == "__main__":
    main()
