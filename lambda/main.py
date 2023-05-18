import json

def lambda_handler(event, context):
  print('Incoming event: ', event)
  for k,v in event.items():
    print(k,v)
    
  return {
    'statusCode': 200,
    'body': json.dumps({'message':'Hello from Lambda!'})}
