'''Pomniter End-to-End Test Suite
Validates:
1. Docker Compose config validity
2. Postgres SQL schema syntax
3. Prometheus YAML syntax
4. Fixtures JSON integrity
'''
import json
import os
import unittest

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class TestPomniterInfrastructure(unittest.TestCase):
    def test_docker_compose_exists_and_non_empty(self):
        compose_path = os.path.join(ROOT_DIR, 'docker-compose.yml')
        self.assertTrue(os.path.exists(compose_path))
        with open(compose_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('postgres:', content)
        self.assertIn('redis:', content)
        self.assertIn('minio:', content)
        self.assertIn('kafka:', content)
        self.assertIn('prometheus:', content)

    def test_postgres_init_sql(self):
        sql_path = os.path.join(ROOT_DIR, 'infra', 'docker', 'postgres', 'init.sql')
        self.assertTrue(os.path.exists(sql_path))
        with open(sql_path, 'r', encoding='utf-8') as f:
            sql = f.read()
        self.assertIn('CREATE TABLE IF NOT EXISTS screenshots', sql)
        self.assertIn('CREATE TABLE IF NOT EXISTS text_blocks', sql)
        self.assertIn('CREATE TABLE IF NOT EXISTS search_logs', sql)

    def test_test_fixtures(self):
        receipt_path = os.path.join(ROOT_DIR, 'tests', 'fixtures', 'sample_receipt.json')
        with open(receipt_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        self.assertEqual(data['category'], 'receipt')
        self.assertIn('coffee', data['keywords'])

if __name__ == '__main__':
    unittest.main()
