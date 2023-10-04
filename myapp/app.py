from flask import Flask, render_template, request, redirect, url_for
from pymongo import MongoClient
from bson.objectid import ObjectId

app = Flask(__name__)

# חיבור למסד הנתונים
client = MongoClient('mongodb://192.168.110.145:27017/')
db = client.mydb  # החלף לשם הבסיס המתאים
laws = db.laws  # החלף לשם הקולקציה המתאימה

# פונקציה לרשימת הצעות החוק
def get_laws():
    return laws.find()

@app.route('/')
def index():
    laws_list = get_laws()
    return render_template('index.html', laws=laws_list)

@app.route('/delete_law/<law_id>')
def delete_law(law_id):
    try:
        law_id = ObjectId(law_id)  # המרת המזהה לטיפוס ObjectId
        result = laws.delete_one({'_id': law_id})
        if result.deleted_count == 1:
            return redirect(url_for('index'))
        return 'המחיקה נכשלה'
    except Exception as e:
        return str(e)

@app.route('/vote_for/<law_id>')
def vote_for(law_id):
    try:
        law_id = ObjectId(law_id)  # המרת המזהה לטיפוס ObjectId
        result = laws.update_one({'_id': law_id}, {'$inc': {'votes_for': 1}})
        if result.modified_count == 1:
            return redirect(url_for('index'))
        return 'ההצבעה נכשלה'
    except Exception as e:
        return str(e)

@app.route('/vote_against/<law_id>')
def vote_against(law_id):
    try:
        law_id = ObjectId(law_id)  # המרת המזהה לטיפוס ObjectId
        result = laws.update_one({'_id': law_id}, {'$inc': {'votes_against': 1}})
        if result.modified_count == 1:
            return redirect(url_for('index'))
        return 'ההצבעה נכשלה'
    except Exception as e:
        return str(e)

@app.route('/add_law', methods=['POST'])
def add_law():
    try:
        # משיג את הפרטים מהטופס
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        id_number = request.form.get('id_number')
        law_title = request.form.get('law_title')
        law_description = request.form.get('law_description')

        # מוסיף את ההצעת חוק למסד הנתונים
        result = laws.insert_one({
            'first_name': first_name,
            'last_name': last_name,
            'id_number': id_number,
            'title': law_title,
            'description': law_description,
            'votes_for': 0,
            'votes_against': 0
        })

        if result.inserted_id:
            return redirect(url_for('index'))
        return 'ההוספה נכשלה'
    except Exception as e:
        return str(e)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
