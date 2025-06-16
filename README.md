# Heat-Related Illness Morbidity and Mortality (NetLogo Model)

This NetLogo simulation models the impact of heat exposure on morbidity and mortality across different age groups, considering factors such as activity level and comorbidities. The model simulates daily heat index variations and tracks the number of individuals who become heat-exhausted, hospitalized, or die due to heat-related illnesses.

This project was developed as part of the requirements for the subject CSC133 – Modelling and Simulation in MSU-IIT. It is submitted along with my paper.


## Features

- **Agent-based simulation** of individuals with age, activity, and comorbidity attributes.
- **Dynamic environment** with daily and monthly heat index changes.
- **Tracks outcomes**: heat exhaustion, hospitalization, recovery, and death.
- **Age-stratified statistics** for morbidity and mortality.
- **Visual interface** with plots and monitors for real-time tracking.

## How It Works

- The environment simulates daily heat index based on monthly averages and random variation.
- Individuals ("turtles") are assigned to age groups and given random activity levels and comorbidity status.
- Each day, individuals may become heat-exposed, leading to possible heat exhaustion, hospitalization, or death, depending on risk factors.
- The model tracks and displays statistics for each outcome.

## How to Use

1. **Open** `heat impact.nlogo` in [NetLogo](https://ccl.northwestern.edu/netlogo/).
2. Click **setup** to initialize the environment and population.
3. Click **start** to run the simulation.
4. Use the interface to monitor:
   - Number of heat-exhausted, hospitalized, and dead individuals.
   - Percentages of each outcome.
   - Plots of ED visits, heat index, hospitalizations, and mortality.

## Interface Items

- **Buttons**: `setup`, `start`
- **Monitors**: Track counts and percentages of outcomes.
- **Plots**: Visualize trends over time for ED visits, heat index, hospitalizations, and mortality.

## Things to Notice

- How heat index fluctuations affect morbidity and mortality.
- Which age groups are most affected.
- The impact of comorbidities and activity levels.

## Extending the Model

- Add more detailed comorbidity profiles.
- Incorporate interventions (e.g., cooling centers).
- Model different climate scenarios or urban/rural differences.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.


*For more information about NetLogo, visit the [NetLogo website](https://ccl.northwestern.edu/netlogo/).*