from HealthGraphPackage import Points
from datetime import datetime, timedelta
import os

# This object is used to pull data from a user token and write it to a file.
class DataSyncObject:
    
#     Path and name of the file to be created. This may vary from PC to PC but currently is hard
#     coded to work on our machine.
    path_to_FISS = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim\Data\SKSE\Plugins\FISS\\"
    file_name = "Exercise_data.txt"
    
    def __init__ (self, userToken):
        self.user_profile = userToken.get_profile()
        
        self.fitness_activity_iter = userToken.get_fitness_activity_iter()
        self.strength_activity_iter = userToken.get_strength_activity_iter()
        self.users_weight_iter = userToken.get_weight_measurement_iter()

        self.points_generator = Points.Points(self.fitness_activity_iter, self.strength_activity_iter, self.users_weight_iter)
    
#     This is the method that should be called outside of this class.
#     The other methods are all internal methods for breaking up code.
    def sync(self):
        file_to_write = self.create_file_contents()
        self.write_file(file_to_write)
        print("Sync complete!")

#     Returns the contents of the file to be written. 
#     This includes header information, newly synced exercises, and previous exercise session data.
    def create_file_contents(self):
#         Initialization of variables to be used.
        previous_file_data = []
        print(self.user_profile)
        print("this is the strength iterator" + str(self.strength_activity_iter))
        first_import_date = ""
        previous_import_date = ""
        first_weeks_points = 0
        first_weeks_points_not_found = True
        first_date = datetime.now()
     
        outstanding_strength_points = 0
        outstanding_fitness_points = 0
        outstanding_sport_points = 0

#         Check if a exercise log file already exists.
#         If it does, we will be reading in:
#             - the first datetime the user synced their account, 
#             - the amount of points they earned in their first week,  
#             - the last datetime they synced,
#             - outstanding points a player has in strength, fitness, and sport
        if os.path.isfile(self.path_to_FISS + self.file_name):
            read_file = open(self.path_to_FISS + self.file_name)
            for i, line in enumerate(read_file):
#                 Depending on the formatting style of the file, we can determine whether it 
#                 has been written by this datasync client or Skyrim's FISS library.

#                 If it is all written in one long line, it has been written by Skyrim's FISS library,
#                 otherwise, it is written by this datasync client.
                if i == 0:
                    try:
                        first_date_index = line.index("<First_import_date>")
                        first_date_in_format = line[first_date_index + 20:first_date_index + 46]
                        first_date = datetime.strptime(first_date_in_format, "%Y-%m-%d %H:%M:%S.%f")
                        print("The first sync date is:" + first_date_in_format)
                        first_week_points_start_index = line.index("<First week points>")
                        first_week_points_end_index = line.index("</First week points>")
                        first_weeks_points = line[first_week_points_start_index + 19: first_week_points_end_index]
                        print("The first week points is " + first_weeks_points)
                        if first_weeks_points != 0:
                            first_weeks_points_not_found = False

                        previous_import_date_index = line.index("<Last_update_date>")
                        previous_import_date = line[previous_import_date_index + 19: previous_import_date_index + 45]
     
                        outstanding_strength_points_start_index = line.index("<Outstanding_strength_points>")
                        outstanding_strength_points_end_index = line.index("</Outstanding_strength_points>")
                        outstanding_strength_points = line[outstanding_strength_points_start_index + 29:outstanding_strength_points_end_index]
                         
                        outstanding_fitness_points_start_index = line.index("<Outstanding_fitness_points>")
                        outstanding_fitness_points_end_index = line.index("</Outstanding_fitness_points>")
                        outstanding_fitness_points = line[outstanding_fitness_points_start_index + 28: outstanding_fitness_points_end_index]
     
                        outstanding_sport_points_start_index = line.index("<Outstanding_sport_points>")
                        outstanding_sport_points_end_index =  line.index("</Outstanding_sport_points>")
                        outstanding_sport_points = line[outstanding_sport_points_start_index + 26: outstanding_sport_points_end_index]
                    except ValueError:
#                         If the file being read is from our datasync client, it will cause a value error.
#                         Technically, this should not happen as a user should not be running our client twice in 
#                         a row, as the launcher will take them to play Skyrim. But if this does happen, a ValueError
#                         occurs. We can catch this error and then read the file in as needs to be without any of the 
#                         other code breaking because of the ValueError.
                        print("File being read is from Python not Skyrim.")
                if i == 3:
                    first_date = line
                    first_date_in_format = first_date[20:46]
                    
#                     If somehow the first sync date has disppeared from the exercise log file, problems will occur.
#                     In this case, we request that the player go enter the date they first synced to fix this problem.
#                     Again this is an emergency check to prevent the system from becoming unusable. This should not
#                     happen in normal circumstances.                    
                    if first_date_in_format == " </Fst":
                        raise Exception("Please enter the first date the game was synced in to the file " + self.file_name 
                                        + " in the directory " + self.path_to_FISS + ". Please format it as follows\n" +
                                        "YYYY-MM-DD 00:00:00:0000\nThank you for your co-operation.")
                    
                    first_date = datetime.strptime(first_date_in_format, "%Y-%m-%d %H:%M:%S.%f")
                    first_import_date = "" +  str("%02d" %first_date.day) + str("%02d" %first_date.month) + str(first_date.year)
                    print("The first import date is :" + first_import_date)
                if i == 4:
                    first_weeks_points_str = line
                    index = first_weeks_points_str.index("</First week points>") - 1
                    first_weeks_points_str = line[20:index]
                    first_weeks_points = int(first_weeks_points_str)
                    if first_weeks_points != 0:
                        first_weeks_points_not_found = False
                if i == 5:
                    previous_import_date = line
                    previous_import_date = previous_import_date[19:45]
                if i == 7:
                    outstanding_strength_points = line
                    outstanding_strength_points_end_index = outstanding_strength_points.index("</Outstanding_strength_points>") - 1
                    outstanding_strength_points = line[30:outstanding_strength_points_end_index]
                if i == 8:
                    outstanding_fitness_points = line
                    outstanding_fitness_points_end_index = outstanding_fitness_points.index("</Outstanding_fitness_points>") - 1
                    outstanding_fitness_points = line[29:outstanding_fitness_points_end_index]
                if i == 9:
                    outstanding_sport_points = line
                    outstanding_sport_points_end_index = outstanding_sport_points.index("</Outstanding_sport_points>") - 1
                    outstanding_sport_points = line[27:outstanding_sport_points_end_index]
            read_file.close()
             
#         If no previous_import_date was found in the file (i.e. the file did not yet exist), import from now onwards.
#         Otherwise, read in from when the last import date was in the file and use that date for importing purposes.
        previous_import_date_object = datetime.now()
        if previous_import_date != "":
            previous_import_date_object = datetime.strptime(previous_import_date, "%Y-%m-%d %H:%M:%S.%f")
          
#         Determine whether it's been a week since the first import date
        one_week_from_first_import = (first_date + timedelta(days = 7))
        first_week_completed = datetime.now() > one_week_from_first_import
        
#         Create an object which stores all of the dates which will be used in figuring out which exercises need to be
#         pulled.
        last_import_data = last_import_data_object(first_date, first_weeks_points, 
                                                    first_weeks_points_not_found,one_week_from_first_import, 
                                                    previous_import_date_object)
        
        newly_synced_exercise_data = self.sync_with_latest_exercises(last_import_data) 
        
        outstanding_strength_points = int(outstanding_strength_points) + newly_synced_exercise_data[0]
        outstanding_fitness_points = int(outstanding_fitness_points) + newly_synced_exercise_data[1]
        outstanding_sport_points = int(outstanding_sport_points) + newly_synced_exercise_data[2]

#         Set up the header information. The first and last lines must be specific lines. If they are not these, FISS
#         cannot read the file in correctly.
#         Everything in the file must also be written with an XML style markup.  
        previous_file_data.append("<fiss><Header><Version>1.2</Version><ModName>P4P</ModName></Header>\n<Data>\n\n")
        previous_file_data.append("<First_import_date> " + str(first_date) + " </First_import_date> \n")
        previous_file_data.append("<Last_update_date> " + str(datetime.now()) + " </Last_update_date> \n\n")
     
        previous_file_data.append("<Outstanding_strength_points> " + str(outstanding_strength_points) + " </Outstanding_strength_points>\n")
        previous_file_data.append("<Outstanding_fitness_points> " + str(outstanding_fitness_points) + " </Outstanding_fitness_points>\n")
        previous_file_data.append("<Outstanding_sport_points> " + str(outstanding_sport_points) + " </Outstanding_sport_points>\n\n")
        previous_file_data.append("<First_week_completed> " + str(first_week_completed) + " </First_week_completed> \n\n")

        
#         Insert the first weeks points information at the top of the file. This is because it makes it easier to read
#         in via Python and also FISS.
        first_week_points = "<First week points> " + str(newly_synced_exercise_data[3]) + " </First week points>\n"
        previous_file_data.insert(2, first_week_points)
        newly_synced_exercise_data.pop(len(newly_synced_exercise_data) - 1)
        
        previous_file_data.append("\n")
        previous_file_data.append("\n</Data>\n</fiss>")
        
        file_to_write = previous_file_data
        
        return file_to_write

#     Save the total points the player has earned from exercises since the last sync and return it via a list.
#     The list is ordered by [new_strength_points, new_fitness_points, new_sport_points, first_week_points)
    def sync_with_latest_exercises(self, last_import_data):
        total_points = [0, 0, 0, 0]
        first_weeks_points = last_import_data.first_weeks_points
        
#         Sport exercises are defined as FitnessActivities with an Other type on Runkeeper.
#         Any exercises in the fitness_activity_iter that have Other as their type are then saved into a list and
#         iterated through later.
        sport_exercises = []
        print("ENTERED THE SYNC METHOS")
        for exercise in self.fitness_activity_iter:
            exercise_date = exercise.get("start_time")

            if (last_import_data.first_weeks_points_not_found and (exercise_date >= last_import_data.first_date)
                and (exercise_date <= last_import_data.one_week_from_first_import)):
                
                exercise_points = self.points_generator.get_points(exercise)
                first_weeks_points += exercise_points
     
            if last_import_data.previous_import_date_object <= exercise_date:
                exercise_points = self.points_generator.get_points(exercise)
                     
                if Points.get_type(exercise) != 'Other':
                    print("CARDIO: " + str(exercise))
                    total_points[1] += exercise_points
                else:
                    sport_exercises.append(exercise)
         
        for exercise in sport_exercises:
            exercise_points = self.points_generator.get_points(exercise)
            print("SPORT: " + str(exercise))
            total_points[2] += exercise_points

        for exercise in self.strength_activity_iter:
            exercise_date = exercise.get("start_time")
     
            if (last_import_data.first_weeks_points_not_found and (exercise_date >= last_import_data.first_date) 
                and (exercise_date <= last_import_data.one_week_from_first_import)):
                
                exercise_points = self.points_generator.get_points(exercise)
                first_weeks_points += exercise_points
     
            if last_import_data.previous_import_date_object <= exercise_date:
                exercise_points = self.points_generator.get_points(exercise)
                print("STRENGTH: " + str(exercise))
                total_points[0] += exercise_points

        total_points[3] = first_weeks_points
        return total_points

    def write_file(self, file_contents):
#         Using the w overwrites any existing file with the same path + name, and creates the file if it does not exist.
        with open(self.path_to_FISS + self.file_name, "w") as fwrite:
            for line in file_contents:
                fwrite.write(line)
        print("Write to file complete")


# Object used to store import data needed to calculate whether an exercise is newer than the last import date,
# as well as if first week points need to be calculated.
class last_import_data_object:
    def __init__(self, first_date, first_weeks_points, first_weeks_points_not_found,
                  one_week_from_first_import, previous_import_date_object):
        
        self.first_date = first_date
        self.first_weeks_points = first_weeks_points
        self.first_weeks_points_not_found = first_weeks_points_not_found
        self.one_week_from_first_import = one_week_from_first_import
        self.previous_import_date_object = previous_import_date_object
