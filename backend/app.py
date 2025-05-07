from flask import Flask, request, jsonify
from flask_cors import CORS
import boto3
import os

app = Flask(__name__)
CORS(app)

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table_name = os.getenv('DYNAMODB_TABLE', 'Campaigns')

@app.before_first_request
def create_table():
    try:
        dynamodb.create_table(
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
    except Exception as e:
        print(f"Table creation skipped: {e}")

@app.route('/campaigns', methods=['GET'])
def get_campaigns():
    table = dynamodb.Table(table_name)
    response = table.scan()
    return jsonify(response['Items'])

@app.route('/campaigns', methods=['POST'])
def add_campaign():
    data = request.json
    table = dynamodb.Table(table_name)
    campaign_id = str(hash(data['title'] + data['start_date']))
    item = {
        'id': campaign_id,
        'title': data['title'],
        'description': data['description'],
        'start_date': data['start_date'],
        'end_date': data['end_date']
    }
    table.put_item(Item=item)
    return jsonify({'message': 'Campaign added successfully'}), 201

if __name__ == '__main__':
    app.run(debug=True)
