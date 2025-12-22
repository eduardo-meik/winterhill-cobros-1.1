#!/usr/bin/env python3
"""
Enrollment Data Analysis Tool
Analyzes JSON enrollment data for duplicates, sharing issues, and test data
Created: 2025-12-22
"""

import json
from collections import defaultdict
from datetime import datetime

# Paste your JSON data here
data = [
    # Your JSON array...
]

def analyze_enrollments(enrollments):
    """Comprehensive analysis of enrollment data"""
    
    # Track various issues
    enrollment_sharing = defaultdict(list)  # enrollment_id -> [students]
    student_year_enrollments = defaultdict(list)  # (student_id, year) -> [enrollments]
    test_students = []
    year_2022_enrollments = []
    
    print("=" * 80)
    print("ENROLLMENT DATA ANALYSIS REPORT")
    print("=" * 80)
    print(f"\nTotal records in dataset: {len(enrollments)}")
    print()
    
    # Analyze each enrollment
    for enrollment in enrollments:
        enroll_id = enrollment['id']
        student_id = enrollment['student_id']
        student_name = enrollment['first_name']
        year = enrollment['year']
        created_at = enrollment['created_at']
        
        # Track enrollment ID sharing
        enrollment_sharing[enroll_id].append({
            'student_id': student_id,
            'name': student_name,
            'year': year,
            'created_at': created_at
        })
        
        # Track student year duplicates
        key = (student_id, year)
        student_year_enrollments[key].append({
            'enrollment_id': enroll_id,
            'name': student_name,
            'created_at': created_at
        })
        
        # Identify test students
        name_lower = student_name.lower()
        if any(term in name_lower for term in ['test', 'testing', 'estudiante', 'junito', 'falso']):
            test_students.append({
                'student_id': student_id,
                'name': student_name,
                'enrollment_id': enroll_id,
                'year': year
            })
        
        # Track year 2022
        if year == 2022:
            year_2022_enrollments.append({
                'enrollment_id': enroll_id,
                'student_id': student_id,
                'name': student_name,
                'created_at': created_at
            })
    
    # ============================================================================
    # ISSUE 1: ENROLLMENT ID SHARING
    # ============================================================================
    print("=" * 80)
    print("ISSUE 1: ENROLLMENT ID SHARING")
    print("=" * 80)
    print("One enrollment ID should NOT have multiple students attached.")
    print()
    
    shared_enrollments = {k: v for k, v in enrollment_sharing.items() if len(v) > 1}
    
    if shared_enrollments:
        print(f"❌ Found {len(shared_enrollments)} enrollments with multiple students")
        print(f"   Total students affected: {sum(len(v) for v in shared_enrollments.values())}")
        print()
        print("Top 10 problematic enrollments:")
        for i, (enroll_id, students) in enumerate(list(shared_enrollments.items())[:10], 1):
            print(f"\n{i}. Enrollment: {enroll_id}")
            print(f"   Students ({len(students)}):")
            for student in students:
                print(f"      - {student['name']} ({student['student_id'][:8]}...)")
    else:
        print("✅ No enrollment ID sharing issues found")
    
    # ============================================================================
    # ISSUE 2: DUPLICATE ENROLLMENTS (SAME STUDENT, SAME YEAR)
    # ============================================================================
    print("\n")
    print("=" * 80)
    print("ISSUE 2: DUPLICATE ENROLLMENTS (SAME STUDENT, SAME YEAR)")
    print("=" * 80)
    print("Students should have only ONE enrollment per academic year.")
    print()
    
    duplicate_students = {k: v for k, v in student_year_enrollments.items() if len(v) > 1}
    
    if duplicate_students:
        print(f"❌ Found {len(duplicate_students)} students with duplicate enrollments")
        print(f"   Total duplicate enrollment records: {sum(len(v) for v in duplicate_students.values())}")
        print()
        print("Top 10 students with duplicates:")
        for i, ((student_id, year), enrollments) in enumerate(list(duplicate_students.items())[:10], 1):
            print(f"\n{i}. Student: {enrollments[0]['name']} ({student_id[:8]}...)")
            print(f"   Year: {year}")
            print(f"   Enrollments ({len(enrollments)}):")
            for enroll in sorted(enrollments, key=lambda x: x['created_at']):
                print(f"      - {enroll['created_at']} | ID: {enroll['enrollment_id'][:8]}...")
    else:
        print("✅ No duplicate enrollments found")
    
    # ============================================================================
    # ISSUE 3: TEST/PLACEHOLDER STUDENTS
    # ============================================================================
    print("\n")
    print("=" * 80)
    print("ISSUE 3: TEST/PLACEHOLDER STUDENTS")
    print("=" * 80)
    print("Students with test names should be removed from production.")
    print()
    
    if test_students:
        # Group by student
        test_by_student = defaultdict(list)
        for test in test_students:
            test_by_student[test['student_id']].append(test)
        
        print(f"❌ Found {len(test_by_student)} test students")
        print(f"   Total test enrollment records: {len(test_students)}")
        print()
        print("Test students found:")
        for student_id, records in test_by_student.items():
            print(f"\n   - {records[0]['name']} ({student_id[:8]}...)")
            print(f"     Enrollments: {len(records)}")
            for rec in records:
                print(f"       Year {rec['year']}: {rec['enrollment_id'][:8]}...")
    else:
        print("✅ No test students found")
    
    # ============================================================================
    # ISSUE 4: YEAR 2022 ENROLLMENTS
    # ============================================================================
    print("\n")
    print("=" * 80)
    print("ISSUE 4: YEAR 2022 ENROLLMENTS (LEGACY/TEST)")
    print("=" * 80)
    print("Enrollments from 2022 (created in 2025) are likely test data.")
    print()
    
    if year_2022_enrollments:
        print(f"❌ Found {len(year_2022_enrollments)} enrollments with year=2022")
        print()
        print("Year 2022 enrollments:")
        for enroll in year_2022_enrollments:
            print(f"   - {enroll['name']} | Created: {enroll['created_at']}")
    else:
        print("✅ No year 2022 enrollments found")
    
    # ============================================================================
    # SUMMARY
    # ============================================================================
    print("\n")
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total enrollment records analyzed: {len(enrollments)}")
    print(f"")
    print(f"Issues found:")
    print(f"  1. Enrollment ID sharing: {len(shared_enrollments)} enrollments")
    print(f"  2. Duplicate enrollments: {len(duplicate_students)} students")
    print(f"  3. Test students: {len(set(t['student_id'] for t in test_students))} students")
    print(f"  4. Year 2022 enrollments: {len(year_2022_enrollments)} records")
    print()
    
    # Calculate records to delete
    records_to_review = 0
    records_to_review += sum(len(v) - 1 for v in shared_enrollments.values())  # Keep 1 per shared enrollment
    records_to_review += sum(len(v) - 1 for v in duplicate_students.values())  # Keep 1 per student/year
    records_to_review += len(test_students)  # Delete all test records
    records_to_review += len(year_2022_enrollments)  # Delete all 2022 records
    
    print(f"Estimated records requiring review/deletion: {records_to_review}")
    print()

if __name__ == "__main__":
    # Check if data is loaded
    if not data:
        print("❌ ERROR: No data loaded. Please paste your JSON array into the 'data' variable.")
        print()
        print("Instructions:")
        print("1. Open this file in a text editor")
        print("2. Find the line: data = []")
        print("3. Replace [] with your JSON array")
        print("4. Save and run: python analyze_json_enrollments.py")
    else:
        analyze_enrollments(data)
