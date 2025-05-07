import json
import pytest
import boto3
import os
from moto import mock_dynamodb
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@pytest.fixture
def dynamodb_table():
    with mock_dynamodb():
        # Créer une table DynamoDB simulée pour les tests
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        table_name = 'Campaigns'
        
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {'AttributeName': 'id', 'KeyType': 'HASH'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'id', 'AttributeType': 'S'}
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5
            }
        )
        
        # Insérer des données de test
        table.put_item(Item={
            'id': '12345',
            'title': 'Test Campaign',
            'description': 'This is a test campaign',
            'start_date': '2025-05-01',
            'end_date': '2025-05-31'
        })
        
        yield table

def test_get_campaigns(client, dynamodb_table):
    """Tester la récupération des campagnes"""
    os.environ['DYNAMODB_TABLE'] = 'Campaigns'
    response = client.get('/campaigns')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert len(data) >= 1
    assert any(item['title'] == 'Test Campaign' for item in data)

def test_add_campaign(client, dynamodb_table):
    """Tester l'ajout d'une nouvelle campagne"""
    os.environ['DYNAMODB_TABLE'] = 'Campaigns'
    
    new_campaign = {
        'title': 'New Test Campaign',
        'description': 'This is a new test campaign',
        'start_date': '2025-06-01',
        'end_date': '2025-06-30'
    }
    
    response = client.post('/campaigns', 
                           data=json.dumps(new_campaign),
                           content_type='application/json')
    
    assert response.status_code == 201
    
    # Vérifier que la campagne a été ajoutée
    get_response = client.get('/campaigns')
    data = json.loads(get_response.data)
    assert any(item['title'] == 'New Test Campaign' for item in data)