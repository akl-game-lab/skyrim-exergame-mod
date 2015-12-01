import HealthGraphPackage

class Points:

	#Database for fitness activities (cardio/sports)
	activity_database = {	

					#sports activities
					'Mountain Biking': 2.1
					,'Competitive Rowing': 2
					,'Kickboxing': 2.5
					,'Soccer': 2
					,'Brazilian Jiu-Jitsu': 2.1
					,'Tennis': 2.4
					,'Swimming': 2.1
					,'Volleyball': 1.8
					,'Ice Hockey': 2.2
					,'Rock Climbing': 1.8
					,'Racquetball': 2
					,'Golf': 1.2
					,'Squash': 2
					,'Rugby': 2
					,'Softball': 1.5
					,'Taekwondo': 1.3
					,'Baseball': 1.5
					,'American Football': 1.9
					,'Snowboarding': 1.7
					,'Skiiing': 1.7
					,'Kayaking': 2
					,'Krav Maga': 2.3
					,'Beach Volleyball': 1.9
					,'Ultimate Frisbee': 2
					,'Wrestling': 2
					,'Street Hockey':2
					,'Roller Derby': 1.7
					,'Ping-Pong': 1.5
					,'Roller Skating': 1.7
					,'Badminton': 2
					,'Surfing': 2.3
					,'Ice Skating': 1.7
					,'Lacrosse': 2
					,'Horseback Riding': 1.2
					,'Fencing': 1.5
					,'Water Polo': 2
					,'Field Hockey': 2
					,'Frisbee': 1.3
					,'Broomball': 1.6
					,'Hand Ball': 2
					,'Basketball': 2

					#cardio activities
					,'Bicycling': 2
					,'Running': 2
					,'Jogging': 1.6
					,'Walking': 1.4
					, 'Elliptical Trainer': 1.7
					, 'Treadmill Running': 1.9
					, 'Treadmill Jogging': 1.6
					, 'Treadmill Walking': 1.3
					, 'Jump Rope': 2.5
					, 'Hiking': 1.7
					, 'Rowing': 2
					, 'Sprint': 2.5
					, 'Stair Climber': 1.7
					, 'Treadmill Sprint': 2.3
					, 'Zumba': 1.6
					, 'Boxing': 2.5
					, 'Skating': 1.4
					, 'Sled Push': 2.5
					, 'Power Walking': 1.5
					, 'Exercise Bike': 1.6
					, 'Sled Sprint': 2.5
					, 'Hill Sprint': 2.5
					, 'Shuttle Run': 2.4
					, 'Keg Carry': 2.5
					, 'Tire Pull': 2.5

						}

	def __init__(self, fitness_iterator, strength_iterator, weight_iterator):
		self.fitness_activity_iter = fitness_iterator
		self.strength_activity_iter = strength_iterator
		self.bodyweight = get_bodyweight(weight_iterator.next())
		

	#iterates through the fitness activities and strength activites then generates the total points for the user
	def get_total_points(self):
		total_points = 0
		
		for feed_item in self.fitness_activity_iter:
			exercise_points = self.get_points(feed_item)
			total_points += exercise_points

		for feed_item in self.strength_activity_iter:
			#may need to do a check here for date before adding points of a feed
			exercise_points = self.get_points(feed_item)
			total_points += exercise_points

		return total_points

	#pass this an activity feed item and it will return points, it will iterate through exercises if it is a strength feed item
	def get_points(self, feed):
		activity = get_activity_type(feed)
		exercise_type = get_type(feed)

		if activity == "FitnessActivity":
			duration = feed.get("duration")/60
			if exercise_type == "Other":

				#sport activity
				sport_act = feed.get_activity_detail()
				sport_type = get_secondary_type(sport_act)
				points = self.activity_database[sport_type] * duration
				return points
			else:
				#cardio activities, if exercise doesn't exist in database return 0
				try:
					points = self.activity_database[exercise_type] * duration
					return points
				except:
					return 0
			
		elif activity == "StrengthActivity":

			#Get type of exercise
			tonnage = 0
			str_act = feed.get_activity_detail()
			info_set = get_exercise_set(str_act)
			for ex_set in info_set:
				weight = get_weight(ex_set)
				
				#adjusting tonnage for bodyweight exercises
				if weight == 0:
					weight = self.bodyweight*0.4
					
				#weight modifier for stupid shrugs	
				if "shrug" in get_exer_name(feed).lower():
					weight = weight/11

					#weight modifier for dumbbell exercises
				if "dumbbell" in get_exer_name(feed).lower():
					weight = weight*2
					
				reps = get_reps(ex_set)
				tonnage += weight * reps

				#29 is an arbitrary constant used to scale tonnage with the points system. See report for more de-tails
				points = int(round(tonnage/29))
				
				
			return points

		return 0


#STATIC WRAPPER METHODS FOR DICTIONARY INFO RETRIEVAL	
def get_exercise_type(act):
	pass

def get_type(feed_item):
	return feed_item.get("type")

def get_secondary_type(act):
	return act.get('secondary_type')

#Give me a feed item and I will return the activity name!
def get_exer_name(feed_item):
	#cardio activity
	if ((get_activity_type(feed_item) == 'FitnessActivity') and not (get_type(feed_item) == 'Other')):
		return get_type(feed_item)
	#sport activity
	elif get_type(feed_item) == 'Other':
		sport_act = feed_item.get_activity_detail()
		return get_secondary_type(sport_act)
	#strength activity
	elif get_activity_type(feed_item) == 'StrengthActivity':
		str_act = feed_item.get_activity_detail()
		return get_secondary_type(str_act.get('exercises')[0])

#returning the list of the sets of a particular strength exercise
def get_exercise_set(str_act):
	return str_act.get('exercises')[0].get('sets')

def get_weight(str_act):
	return str_act.get('weight')

def get_reps(str_act):
	return str_act.get('repetitions')

#gets the activity type of a feed item (strength or fitness)
def get_activity_type(feed_item):
	return feed_item.get("uri")[0]
	
def get_start_time(act):
	return act.get("start_time")

def get_bodyweight(user):
	return user.get("weight")
	
	
