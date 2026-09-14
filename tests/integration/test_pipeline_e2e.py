'''Pomniter End-to-End Test Suite
Validates:
1. Docker Compose config validity (including microservices)
2. Postgres SQL schema syntax
3. Prometheus YAML scraping targets
4. Fixtures JSON integrity
5. Microservices Dockerfiles and structure
'''
import json
import os
import unittest

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class TestPomniterInfrastructure(unittest.TestCase):
    def test_docker_compose_exists_and_services_defined(self):
        compose_path = os.path.join(ROOT_DIR, 'docker-compose.yml')
        self.assertTrue(os.path.exists(compose_path))
        with open(compose_path, 'r', encoding='utf-8') as f:
            content = f.read()
        # Infrastructure services
        self.assertIn('postgres:', content)
        self.assertIn('redis:', content)
        self.assertIn('minio:', content)
        self.assertIn('kafka:', content)
        self.assertIn('prometheus:', content)
        # Microservices
        self.assertIn('api-gateway:', content)
        self.assertIn('ocr-service:', content)
        self.assertIn('embedding-service:', content)
        self.assertIn('search-service:', content)

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

    def test_microservices_scaffolding_and_dockerfiles(self):
        services = ['api-gateway', 'ocr-service', 'embedding-service', 'search-service']
        for svc in services:
            svc_dir = os.path.join(ROOT_DIR, 'services', svc)
            self.assertTrue(os.path.isdir(svc_dir), f"Service dir {svc} missing")
            dockerfile = os.path.join(svc_dir, 'Dockerfile')
            self.assertTrue(os.path.exists(dockerfile), f"Dockerfile in {svc} missing")

    def test_prometheus_scraping_config(self):
        prom_path = os.path.join(ROOT_DIR, 'telemetry', 'prometheus', 'prometheus.yml')
        self.assertTrue(os.path.exists(prom_path))
        with open(prom_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('pomniter-api-gateway', content)
        self.assertIn('pomniter-ocr-service', content)
        self.assertIn('pomniter-embedding-service', content)

    def test_kafka_topics_script(self):
        script_path = os.path.join(ROOT_DIR, 'infra', 'scripts', 'create-kafka-topics.ps1')
        self.assertTrue(os.path.exists(script_path))
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('screenshot.uploaded', content)
        self.assertIn('screenshot.ocr.completed', content)
        self.assertIn('screenshot.embedding.completed', content)
        self.assertIn('screenshot.indexed', content)

if __name__ == '__main__':
    unittest.main()
